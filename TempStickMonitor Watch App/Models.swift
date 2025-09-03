import Foundation
import SwiftUI

struct TempStickReading: Codable, Identifiable, Hashable {
    var id: Date { sensorTime } 
    let temperature: Double
    let humidity: Double
    let rssi: Int
    let timeToConnect: Int
    let voltage: Double
    let sensorTime: Date
    let offline: Int
    
    enum CodingKeys: String, CodingKey {
        case temperature, humidity, rssi
        case timeToConnect = "time_to_connect"
        case voltage
        case sensorTime = "sensor_time"
        case offline
    }
    
    // Custom decoder initializer
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        temperature = try container.decode(Double.self, forKey: .temperature)
        humidity = try container.decode(Double.self, forKey: .humidity)
        rssi = try container.decode(Int.self, forKey: .rssi)
        timeToConnect = try container.decode(Int.self, forKey: .timeToConnect)
        voltage = try container.decode(Double.self, forKey: .voltage)
        sensorTime = try container.decode(Date.self, forKey: .sensorTime)
        offline = try container.decode(Int.self, forKey: .offline)
    }

    func temperatureForUnit(_ unit: TemperatureUnit) -> Double {
        switch unit {
        case .celsius: return temperature
        case .fahrenheit: return temperature * 9/5 + 32
        case .kelvin: return temperature + 273.15
        }
    }
    
    var isOnline: Bool {
        Date().timeIntervalSince(sensorTime) < 900
    }

}

enum TemperatureUnit: String, Codable, CaseIterable {
    case celsius = "C"
    case fahrenheit = "F"
    case kelvin = "K"
    
    var displayName: String {
        switch self {
        case .celsius: return "Celsius"
        case .fahrenheit: return "Fahrenheit"
        case .kelvin: return "Kelvin"
        }
    }
    
    var symbol: String {
        switch self {
        case .celsius: return "°C"
        case .fahrenheit: return "°F"
        case .kelvin: return "K"
        }
    }
}

struct TempStickSensor: Codable, Identifiable, Hashable {
    var id: String { sensorId }
    let sensorId: String
    let sensorName: String
    let lastTemp: Double?
    let lastHumidity: Double?
    let batteryPct: Int?
    let lastCheckin: String?
    
    enum CodingKeys: String, CodingKey {
        case sensorId = "sensor_id"
        case sensorName = "sensor_name"
        case lastTemp = "last_temp"
        case lastHumidity = "last_humidity"
        case batteryPct = "battery_pct"
        case lastCheckin = "last_checkin"
    }
    
    // Custom decoder initializer
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
            sensorId = try container.decode(String.self, forKey: .sensorId)  // ✅ Simple string decode

        sensorName = try container.decode(String.self, forKey: .sensorName)
        lastTemp = try container.decodeIfPresent(Double.self, forKey: .lastTemp)
        lastHumidity = try container.decodeIfPresent(Double.self, forKey: .lastHumidity)
        batteryPct = try container.decodeIfPresent(Int.self, forKey: .batteryPct)
        lastCheckin = try container.decodeIfPresent(String.self, forKey: .lastCheckin)
        // id gets its default value from the property declaration
    }
}

struct SensorConfiguration: Codable, Identifiable, Hashable {
    var id: String { sensorId }
    var sensorId: String
    var name: String
    var pollingInterval: TimeInterval
    var isEnabled: Bool
    var temperatureUnit: TemperatureUnit
    
    enum CodingKeys: String, CodingKey {
        case sensorId = "sensor_id"
        case name
        case pollingInterval = "polling_interval"
        case isEnabled = "is_enabled"
        case temperatureUnit = "temperature_unit"
    }
    
    init(sensorId: String, name: String, pollingInterval: TimeInterval = 60.0, isEnabled: Bool = true, temperatureUnit: TemperatureUnit = .fahrenheit) {
        self.sensorId = sensorId
        self.name = name
        self.pollingInterval = pollingInterval
        self.isEnabled = isEnabled
        self.temperatureUnit = temperatureUnit
    }
    
    // Custom decoder initializer
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        sensorId = try container.decodeStringLike(.sensorId)
        name = try container.decode(String.self, forKey: .name)
        pollingInterval = try container.decode(TimeInterval.self, forKey: .pollingInterval)
        isEnabled = try container.decode(Bool.self, forKey: .isEnabled)
        temperatureUnit = try container.decode(TemperatureUnit.self, forKey: .temperatureUnit)
        // id gets its default value from the property declaration
    }
    
    // Custom Equatable conformance (ignoring id)
    static func == (lhs: SensorConfiguration, rhs: SensorConfiguration) -> Bool {
        return lhs.sensorId == rhs.sensorId &&
               lhs.name == rhs.name &&
               lhs.pollingInterval == rhs.pollingInterval &&
               lhs.isEnabled == rhs.isEnabled &&
               lhs.temperatureUnit == rhs.temperatureUnit
    }
    
    // Custom Hashable conformance (ignoring id)
    func hash(into hasher: inout Hasher) {
        hasher.combine(sensorId)
        hasher.combine(name)
        hasher.combine(pollingInterval)
        hasher.combine(isEnabled)
        hasher.combine(temperatureUnit)
    }
}

struct AppSettings: Codable {
    var apiKey: String?
    var globalPollingInterval: TimeInterval?
    var sensorConfigurations: [SensorConfiguration]
    var useGlobalPolling: Bool
    var defaultTemperatureUnit: TemperatureUnit
    
    init() {
        self.apiKey = nil
        self.globalPollingInterval = 60.0
        self.sensorConfigurations = []
        self.useGlobalPolling = false
        self.defaultTemperatureUnit = .fahrenheit
    }
}

struct TempStickApiResponse<T: Decodable>: Decodable {
    let data: T
    let type: String?
    let message: String?
}

struct SensorsResponse: Decodable {
    let items: [TempStickSensor]
}

struct ReadingsResponse: Decodable {
    let readings: [TempStickReading]
}

extension KeyedDecodingContainer {
    /// Decode a value that might be a String or a number, normalized to String.
    func decodeStringLike(_ key: Key) throws -> String {
        if let s = try? decode(String.self, forKey: key) { return s }
        if let i = try? decode(Int.self,    forKey: key) { return String(i) }
        if let d = try? decode(Double.self, forKey: key) { return String(d) }
        throw DecodingError.keyNotFound(
            key,
            .init(codingPath: codingPath, debugDescription: "Expected string or number for \(key)")
        )
    }
}
