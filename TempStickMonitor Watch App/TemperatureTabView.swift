import SwiftUI
import WatchKit

struct TemperatureTabView: View {
  @Environment(WatchModel.self) private var watchModel

  var body: some View {
    TabView {

      ForEach(watchModel.settings.sensorConfigurations) { config in
        if config.isEnabled {
          VStack {
            
            Text(config.name)
              .font(.caption2)

            Spacer()

            watchModel.currentReadings[config.sensorId]
              .map { TempStickReadingView(reading: $0, unit: config.temperatureUnit) }

          }
        }
      }

      SettingsInfoView()
    }
    .tabViewStyle(PageTabViewStyle())
    .onAppear {
      scheduleBackgroundRefresh()
    }
  }

  private func scheduleBackgroundRefresh() {
    let refreshDate = Date().addingTimeInterval(15 * 60)

    // Option 1: Use nil if you don't need userInfo
    WKExtension.shared().scheduleBackgroundRefresh(
      withPreferredDate: refreshDate,
      userInfo: nil
    ) { error in
      if let error = error {
        print("Failed to schedule background refresh: \(error)")
      }
    }
  }
}
