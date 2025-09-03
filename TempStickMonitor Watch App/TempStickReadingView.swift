import SwiftUI

struct TempStickReadingView: View {
  let reading: TempStickReading
  let unit: TemperatureUnit

  var displayTemp: Double {
    switch unit {
    case .celsius:
      return reading.temperature
    case .fahrenheit:
      return reading.temperature * 9 / 5 + 32
    case .kelvin:
      return reading.temperature + 273.15
    }
  }

  var unitLabel: String {
    switch unit {
    case .celsius: return "C"
    case .fahrenheit: return "F"
    case .kelvin: return "K"
    }
  }

  var body: some View {
    VStack(spacing: 16) {

      VStack(spacing: 4) {
        Text("\(displayTemp, specifier: "%.1f")° \(unitLabel)")
          .font(.system(size: 24, weight: .semibold, design: .rounded))
      }

      HStack {
        Image(systemName: "humidity")
          .foregroundColor(.blue)

        Text("\(reading.humidity, specifier: "%.0f")%")
          .font(.subheadline)
      }

      VStack(spacing: 4) {
        HStack {
          Circle()
            .frame(width: 8, height: 8)

          Text(reading.isOnline ? "Online" : "Offline")
            .font(.caption2)
        }

        Text("Updated \(reading.sensorTime, style: .time)")
          .font(.caption2)
          .foregroundColor(.secondary)
      }
    }
    .scenePadding(.horizontal)
  }
}
