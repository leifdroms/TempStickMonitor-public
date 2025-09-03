import SwiftUI

@main
struct TempStickMonitor_Watch_AppApp: App {
    @State private var watchModel = WatchModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(watchModel)
        }
    }
}
