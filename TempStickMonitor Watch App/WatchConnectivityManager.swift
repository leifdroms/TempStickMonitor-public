import WatchConnectivity
import SwiftUI

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
    
    
    func requestDataSync() {
        guard session.activationState == .activated && session.isReachable else { return }
        
        let message = ["type": "request_sync"]
        session.sendMessage(message, replyHandler: nil) { error in
            print("Failed to request sync: \(error)")
        }
    }
}

extension WatchConnectivityManager: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
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
    
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
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
        if let settingsData = data["settings"] as? Data {
            do {
                let settings = try decoder.decode(AppSettings.self, from: settingsData)
                NotificationCenter.default.post(name: .settingsReceived, object: settings)
            } catch {
                print("Failed to decode received settings: \(error)")
            }
        }
        
        if let readingsData = data["readings"] as? Data {
            do {
                let readings = try decoder.decode([String: TempStickReading].self, from: readingsData)
                NotificationCenter.default.post(name: .readingsReceived, object: readings)
            } catch {
                print("Failed to decode received readings in watch app: \(error)")
            }
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
    static let settingsReceived = Notification.Name("settingsReceived")
    static let readingsReceived = Notification.Name("readingsReceived")
}
