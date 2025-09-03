import SwiftUI

struct ContentView: View {
    @Environment(WatchModel.self) private var watchModel
    
    var body: some View {
        NavigationStack {
            if watchModel.settings.apiKey == nil {
                SetupRequiredView()
            } else {
                TemperatureTabView()
            }
        }
        .onAppear {
            watchModel.startPolling()
        }
        .onDisappear {
            watchModel.stopPolling()
        }
    }
}
