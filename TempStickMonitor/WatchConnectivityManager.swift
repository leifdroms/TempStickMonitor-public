import SwiftUI
import WatchConnectivity

@Observable
class WatchConnectivityManager: NSObject {
  var isConnected = false
  var isPaired = false
  var isWatchAppInstalled = false
  var lastSyncDate: Date?

  private let session: WCSession
  private let encoder = JSONEncoder()
  private let decoder = JSONDecoder()

  override init() {
    guard WCSession.isSupported() else {
      fatalError("WCSession not supported")
    }

    self.session = WCSession.default
    super.init()

    encoder.dateEncodingStrategy = .iso8601
    decoder.dateDecodingStrategy = .iso8601

    session.delegate = self
    session.activate()
  }

  func syncSettings(_ settings: AppSettings) {
    guard session.activationState == .activated else { return }

    #if os(iOS)
      guard session.isWatchAppInstalled else { return }
    #endif

    do {
      let data = try encoder.encode(settings)
      let message = ["settings": data]
      try session.updateApplicationContext(message)
      lastSyncDate = Date()
    } catch {
      print("Failed to sync settings: \(error)")
    }
  }

  func syncReadings(_ readings: [String: TempStickReading]) {
    guard session.activationState == .activated else { return }

    #if os(iOS)
      guard session.isWatchAppInstalled else { return }
    #endif

    do {
      let data = try encoder.encode(readings)
      let message = ["readings": data]
      try session.updateApplicationContext(message)
    } catch {
      print("Failed to sync readings: \(error)")
    }
  }

  func requestDataSync() {
    guard session.activationState == .activated && session.isReachable else { return }

    let message = ["type": "request_sync"]
    session.sendMessage(message, replyHandler: nil) { error in
      print("Failed to request sync: \(error)")
    }
  }
}

extension WatchConnectivityManager: WCSessionDelegate {
  func session(
    _ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState,
    error: Error?
  ) {
    DispatchQueue.main.async {
      self.isConnected = activationState == .activated
      #if os(iOS)
        self.isPaired = session.isPaired
        self.isWatchAppInstalled = session.isWatchAppInstalled
      #endif
    }

    if let error = error {
      print("WCSession activation failed: \(error)")
    }
  }

  func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any])
  {
    DispatchQueue.main.async {
      self.handleReceivedData(applicationContext)
    }
  }

  func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
    DispatchQueue.main.async {
      self.handleReceivedData(message)
    }
  }

  private func handleReceivedData(_ data: [String: Any]) {

    if let requestData = data["type"] as? String, requestData == "request_sync" {
      NotificationCenter.default.post(name: .requestDataSync, object: nil)
    }
  }

  #if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {
      print("WCSession became inactive")
    }

    func sessionDidDeactivate(_ session: WCSession) {
      print("WCSession deactivated - reactivating")
      WCSession.default.activate()
    }
  #endif
}

extension Notification.Name {
  static let requestDataSync = Notification.Name("requestDataSync")
}
