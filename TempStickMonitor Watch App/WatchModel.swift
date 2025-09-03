import SwiftUI

@Observable
class WatchModel {
  var settings = AppSettings()
  var currentReadings: [String: TempStickReading] = [:]
  var isLoading = false
  var errorMessage: String?

  private let tempStickService: TempStickServiceProtocol
  private let watchConnectivity: WatchConnectivityManager
  private var pollingTask: Task<Void, Never>?

  init(
    tempStickService: TempStickServiceProtocol = TempStickService(),
    watchConnectivity: WatchConnectivityManager = WatchConnectivityManager()
  ) {
    self.tempStickService = tempStickService
    self.watchConnectivity = watchConnectivity

    setupNotifications()
    loadSettings()
  }

  private typealias ReadingsBySensor = [String: TempStickReading]
  private var readingsObserver: NSObjectProtocol?
  private var settingsObserver: NSObjectProtocol?

  private func setupNotifications() {
    let center = NotificationCenter.default

    readingsObserver = center.addObserver(
      forName: .readingsReceived,
      object: nil,
      queue: .main
    ) { [weak self] note in
      guard let self else { return }
      // Hard failure if wrong type
      guard let dict = note.object as? ReadingsBySensor else {
        assertionFailure("Expected [String: TempStickReading] in .object")
        return
      }

      // Soft skip if empty
      guard !dict.isEmpty else {
        print("ℹ️ readingsReceived: dictionary was empty, ignoring update")
        return
      }

      self.currentReadings = dict

    }

    // SETTINGS
    settingsObserver = center.addObserver(
      forName: .settingsReceived,
      object: nil,
      queue: .main
    ) { [weak self] note in
      guard let self else { return }

      if let s = note.object as? AppSettings {
        self.settings = s
      } else if let s = note.userInfo?["settings"] as? AppSettings {
        self.settings = s
      } else if let data = note.userInfo?["settingsData"] as? Data {
        // if you send settings as Data (WCSession-friendly), decode here
        do { self.settings = try JSONDecoder().decode(AppSettings.self, from: data) } catch {
          print("⚠️ failed to decode settings:", error)
        }
      } else {
        print(
          "⚠️ .settingsReceived had unexpected payload:", String(describing: note.object),
          note.userInfo ?? [:])
        return
      }

      startPolling()
      print("✅ settings applied (useGlobalPolling=\(self.settings.useGlobalPolling))")
    }

  }

  deinit {
    if let t = readingsObserver {
      NotificationCenter.default.removeObserver(t)
    }

    if let t = settingsObserver {
      NotificationCenter.default.removeObserver(t)
    }

  }

  private func loadSettings() {
    if let data = UserDefaults.standard.data(forKey: "tempstick_watch_settings"),
      let savedSettings = try? JSONDecoder().decode(AppSettings.self, from: data)
    {
      settings = savedSettings
    }
  }

  private func saveSettings() {
    if let data = try? JSONEncoder().encode(settings) {
      UserDefaults.standard.set(data, forKey: "tempstick_watch_settings")
    }
  }

  func startPolling() {
    stopPolling()

    guard let apiKey = settings.apiKey,
      !settings.sensorConfigurations.isEmpty
    else {
      return
    }

    pollingTask = Task { [weak self] in
      while !Task.isCancelled {
        await self?.fetchAllReadings()

        let interval =
          self?.settings.useGlobalPolling == true
          ? (self?.settings.globalPollingInterval ?? 600.0) : 600.0

        do {
          try await Task.sleep(for: .seconds(interval))
        } catch {
          break
        }
      }
    }
  }

  func stopPolling() {
    pollingTask?.cancel()
    pollingTask = nil
  }

  @MainActor
  func fetchAllReadings() async {
    guard let apiKey = settings.apiKey else { return }

    isLoading = true
    errorMessage = nil
    var newReadings: [String: TempStickReading] = [:]
    var errors: [String] = []

    for config in settings.sensorConfigurations where config.isEnabled {
      do {
        let reading = try await tempStickService.fetchLatestReading(
          sensorId: config.sensorId,
          apiKey: apiKey
        )

        newReadings[config.sensorId] = reading
      } catch {
        errors.append("Failed to fetch \(config.name): \(error.localizedDescription)")
      }
    }

    currentReadings = newReadings

    errorMessage = errors.isEmpty ? nil : errors.joined(separator: "\n")
    isLoading = false
  }

  func requestSyncFromiPhone() {
    watchConnectivity.requestDataSync()
  }
}
