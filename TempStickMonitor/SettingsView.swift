import SwiftUI

struct SettingsView: View {
    @Environment(AppModel.self) private var appModel
    @State private var apiKeyInput = ""
    @State private var showingApiKey = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TempStickApiKeyInputView(
                        apiKey: $apiKeyInput,
                        isValid: appModel.validateApiKey(apiKeyInput)
                    )
                } header: {
                    Text("TempStick Authentication")
                } footer: {
                    Text("Your TempStick API key is stored securely in Keychain. Find your API key in the TempStick mobile app.")
                }
                
                Section("Default Temperature Unit") {
                    Picker("Unit", selection: Binding(
                        get: { appModel.settings.defaultTemperatureUnit },
                        set: { newValue in
                            appModel.settings.defaultTemperatureUnit = newValue
                        }
                    )) {
                        ForEach(TemperatureUnit.allCases, id: \.self) { unit in
                            Text(unit.displayName).tag(unit)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Section("Polling Configuration") {
                    Toggle("Use Global Polling", isOn: Binding(
                        get: { appModel.settings.useGlobalPolling },
                        set: { newValue in
                            appModel.settings.useGlobalPolling = newValue
                        }
                    ))
                    
                    if appModel.settings.useGlobalPolling {
                        Picker("Global Interval", selection: Binding(
                            get: { appModel.settings.globalPollingInterval ?? 60.0 },
                            set: { newValue in
                                appModel.settings.globalPollingInterval = newValue
                            }
                        )) {
                            Text("10 minutes").tag(600.0)
                            Text("15 minutes").tag(900.0)
                            Text("30 minutes").tag(1800.0)
                        }
                    }
                }
                
                Section("Individual Sensor Settings") {
                    ForEach(appModel.settings.sensorConfigurations.indices, id: \.self) { index in
                        SensorConfigView(
                            configuration: Binding(
                                get: { appModel.settings.sensorConfigurations[index] },
                                set: { newValue in
                                    appModel.settings.sensorConfigurations[index] = newValue
                                }
                            ),
                            useGlobalPolling: appModel.settings.useGlobalPolling
                        )
                    }
                }
                
                Section {
                    Button("Save Settings") {
                        Task {
                            appModel.settings.apiKey = apiKeyInput.isEmpty ? nil : apiKeyInput
                            await appModel.saveSettings()
                        }
                    }
                    .disabled(!appModel.validateApiKey(apiKeyInput) && !apiKeyInput.isEmpty)
                    
                    if appModel.isWatchAppInstalled {
                        Button("Sync to Apple Watch") {
                            appModel.syncSettingsToWatch()
                        }
                        .foregroundColor(.blue)
                    }
                }
            }
            .navigationTitle("Settings")
            .onAppear {
                apiKeyInput = appModel.settings.apiKey ?? ""
            }
        }
    }
}

struct TempStickApiKeyInputView: View {
    @Binding var apiKey: String
    let isValid: Bool
    @State private var isSecure = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Group {
                    if isSecure {
                        SecureField("Enter TempStick API Key", text: $apiKey)
                    } else {
                        TextField("Enter TempStick API Key", text: $apiKey)
                    }
                }
                .textContentType(.password)
                .autocapitalization(.none)
                .autocorrectionDisabled()
                .font(.system(.body, design: .monospaced))
                
                Button(action: { isSecure.toggle() }) {
                    Image(systemName: isSecure ? "eye" : "eye.slash")
                        .foregroundColor(.secondary)
                }
            }
            
            if !apiKey.isEmpty {
                HStack {
                    Image(systemName: isValid ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(isValid ? .green : .red)
                    
                    Text(isValid ? "Valid API key format" : "Invalid API key format")
                        .font(.caption)
                        .foregroundColor(isValid ? .green : .red)
                }
            }
        }
    }
}

struct SensorConfigView: View {
    @Binding var configuration: SensorConfiguration
    let useGlobalPolling: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(configuration.name)
                    .font(.headline)
                Spacer()
                Toggle("", isOn: Binding(
                    get: { configuration.isEnabled },
                    set: { newValue in
                        configuration.isEnabled = newValue
                    }
                ))
                .labelsHidden()
            }
            
            if !useGlobalPolling {
                HStack {
                    Text("Polling Interval:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Picker("Interval", selection: Binding(
                        get: { configuration.pollingInterval },
                        set: { newValue in
                            configuration.pollingInterval = newValue
                        }
                    )) {
                        Text("10m").tag(600.0)
                        Text("15m").tag(900.0)
                        Text("30m").tag(1800.0)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
            }
            
            HStack {
                Text("Temperature Unit:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Picker("Unit", selection: Binding(
                    get: { configuration.temperatureUnit },
                    set: { newValue in
                        configuration.temperatureUnit = newValue
                    }
                )) {
                    Text("°F").tag(TemperatureUnit.fahrenheit)
                    Text("°C").tag(TemperatureUnit.celsius)
                }
                .pickerStyle(SegmentedPickerStyle())
            }
        }
        .padding(.vertical, 4)
    }
}
