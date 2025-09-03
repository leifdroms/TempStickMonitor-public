import SwiftUI

@main
struct TempStickMonitorApp: App {
    @State private var appModel = AppModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appModel)
        }
    }
}
