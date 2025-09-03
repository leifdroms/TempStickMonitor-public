import SwiftUI

@Observable
class AppModel {
    var settings = AppSettings()
    var sensors: [TempStickSensor] = []
    var currentReadings: [String: TempStickReading] = [:]
    var isLoading = false
    var errorMessage: String?
    
    private let tempStickService: TempStickServiceProtocol
    private let keychainService: KeychainServiceProtocol
    private let watchConnectivity: WatchConnectivityManager
    
    init(
        tempStickService: TempStickServiceProtocol = TempStickService(),
        keychainService: KeychainServiceProtocol = KeychainService(),
        watchConnectivity: WatchConnectivityManager = WatchConnectivityManager()
    ) {
        self.tempStickService = tempStickService
        self.keychainService = keychainService
        self.watchConnectivity = watchConnectivity
        
        loadSettings()
        setupNotifications()
    }
    
   private var requestSyncObserver: NSObjectProtocol?

private func setupNotifications() {
    let center = NotificationCenter.default

    // Fire when any part of the app posts `.requestDataSync`
    requestSyncObserver = center.addObserver(
        forName: .requestDataSync,
        object: nil,
        queue: .main
    ) { [weak self] _ in
        guard let self else { return }
        // push current settings to the peer
        self.watchConnectivity.syncSettings(self.settings)
        self.watchConnectivity.syncReadings(self.currentReadings)
    }
}

deinit {
    if let t = requestSyncObserver { NotificationCenter.default.removeObserver(t) }
}
    
    func loadSettings() {
        settings.apiKey = try? keychainService.load(for: "tempstick_api_key")
        
        if let data = UserDefaults.standard.data(forKey: "tempstick_settings"),
           let savedSettings = try? JSONDecoder().decode(AppSettings.self, from: data) {
            settings.globalPollingInterval = savedSettings.globalPollingInterval
            settings.sensorConfigurations = savedSettings.sensorConfigurations
            settings.useGlobalPolling = savedSettings.useGlobalPolling
            settings.defaultTemperatureUnit = savedSettings.defaultTemperatureUnit
        }
    }
    
    func saveSettings() async {
        if let apiKey = settings.apiKey {
            try? keychainService.save(apiKey, for: "tempstick_api_key")
        }
        
        if let data = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(data, forKey: "tempstick_settings")
        }
        
        watchConnectivity.syncSettings(settings)
        
        if settings.apiKey != nil {
            await fetchSensors()
        }
    }
    
    @MainActor
    func fetchSensors() async {
        guard let apiKey = settings.apiKey else {
            errorMessage = "TempStick API key not configured"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            sensors = try await tempStickService.fetchSensors(apiKey: apiKey)
            updateSensorConfigurations()
            await fetchAllReadings()
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    @MainActor
    func fetchAllReadings() async {
        guard let apiKey = settings.apiKey else { return }
        
        var newReadings: [String: TempStickReading] = [:]
        var errors: [String] = []

        for sensor in sensors {
            do {
                let reading = try await tempStickService.fetchLatestReading(
                    sensorId: sensor.sensorId,
                    apiKey: apiKey
                )

                newReadings[sensor.sensorId] = reading
            } catch {
                errors.append("Failed to fetch reading for \(sensor.sensorName): \(error.localizedDescription)")
            }
        }
        
        currentReadings = newReadings
        
        if !errors.isEmpty {
            errorMessage = errors.joined(separator: "\n")
        }
        
        watchConnectivity.syncReadings(currentReadings)
    }
    
    private func updateSensorConfigurations() {

        let existingSensorIds = Set(settings.sensorConfigurations.map { $0.sensorId })
        
        for sensor in sensors {
            if !existingSensorIds.contains(sensor.sensorId) {
                let config = SensorConfiguration(
                    sensorId: sensor.sensorId,
                    name: sensor.sensorName,
                    pollingInterval: 600.0,
                    isEnabled: true,
                    temperatureUnit: settings.defaultTemperatureUnit
                )
                settings.sensorConfigurations.append(config)
            }
        }
    }
    
    func validateApiKey() -> Bool {
        guard let apiKey = settings.apiKey else { return false }
        return apiKey.count >= 16 && apiKey.allSatisfy { $0.isASCII && !$0.isWhitespace }
    }
  
  // Add this new one - validates any provided key string
  func validateApiKey(_ key: String) -> Bool {
      return key.count >= 16 && key.allSatisfy { $0.isASCII && !$0.isWhitespace }
  }
  
  var isWatchAppInstalled: Bool {
      watchConnectivity.isWatchAppInstalled
  }

  /// Syncs the current settings to the Apple Watch
  func syncSettingsToWatch() {
      watchConnectivity.syncSettings(settings)
  }
}
