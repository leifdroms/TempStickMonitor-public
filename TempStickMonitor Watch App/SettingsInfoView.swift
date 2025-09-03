import SwiftUI

struct SettingsInfoView: View {
    @Environment(WatchModel.self) private var watchModel
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("TempStick Config")
                    .font(.headline)
                    .padding(.bottom, 4)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("API Key")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if let apiKey = watchModel.settings.apiKey {
                        Text("\(String(apiKey.prefix(8)))...")
                            .font(.system(.caption, design: .monospaced))
                    } else {
                        Text("Not configured")
                            .foregroundColor(.red)
                    }
                }
                
                Divider()
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Polling Settings")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if watchModel.settings.useGlobalPolling {
                      Text("Global: \((watchModel.settings.globalPollingInterval ?? 60) / 60) min")
                            .font(.caption2)
                    } else {
                        Text("Individual intervals:")
                            .font(.caption2)
                        
                        ForEach(watchModel.settings.sensorConfigurations) { config in
                            if config.isEnabled {
                                HStack {
                                    Text(config.name)
                                        .font(.caption2)
                                    Spacer()
                                  Text("\(Int((config.pollingInterval ?? 60) / 60)) min")
                                        .font(.caption2)
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                }
                
                Divider()
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Active Sensors")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    ForEach(watchModel.settings.sensorConfigurations) { config in
                        if config.isEnabled {
                            HStack {
                                Circle()
                                    .fill(.green)
                                    .frame(width: 6, height: 6)
                                
                                Text(config.name)
                                    .font(.caption2)
                                
                                Spacer()
                                
                                Text(config.temperatureUnit.symbol)
                                    .font(.caption2)
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
                
                Divider()
                
                Button("Request Sync") {
                    watchModel.requestSyncFromiPhone()
                }
                .font(.caption)
                .buttonStyle(.bordered)
            }
            .padding()
        }
    }
}
