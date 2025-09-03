import SwiftUI

struct SensorRowView: View {
    let sensor: TempStickSensor
    let reading: TempStickReading?
    @Environment(AppModel.self) private var appModel
    
    var sensorConfig: SensorConfiguration? {
        appModel.settings.sensorConfigurations.first { $0.sensorId == sensor.sensorId }
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(sensor.sensorName)
                    .font(.headline)
                
                Text("ID: \(sensor.sensorId)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if let reading = reading, let config = sensorConfig {
                    HStack {
                        let temp = reading.temperatureForUnit(config.temperatureUnit)
                        Text("\(temp, specifier: "%.1f")\(config.temperatureUnit.symbol)")
                            .font(.subheadline)
                            .foregroundColor(.primary)
                        
                        Text("|  \(reading.humidity, specifier: "%.0f")% RH")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Text("Updated \(reading.sensorTime, style: .time)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                if let config = sensorConfig {
                    Text("Polling: \(Int(config.pollingInterval / 60))min")
                        .font(.caption2)
                        .foregroundColor(.blue)
                }
            }
            
            Spacer()
            
            VStack {
                if let reading = reading {
                    Circle()
                        .frame(width: 12, height: 12)
                    if let battery = sensor.batteryPct.map({ Double($0) / 100.0 }) {
                        Text("\(Int(battery * 100))%")
                            .font(.caption2)
                            .foregroundColor(battery < 0.2 ? .red : .secondary)
                    }
                }
                
                if let config = sensorConfig {
                    Toggle("", isOn: .constant(config.isEnabled))
                        .labelsHidden()
                        .disabled(true)
                }
            }
        }
        .padding(.vertical, 2)
    }
}
