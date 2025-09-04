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
      watchModel.scheduleBackgroundRefresh()
    }
  }


}
