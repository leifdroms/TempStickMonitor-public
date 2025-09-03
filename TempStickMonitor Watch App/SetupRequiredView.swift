import SwiftUI

struct SetupRequiredView: View {
  @Environment(WatchModel.self) private var watchModel

  var body: some View {
    VStack(spacing: 16) {
      HStack(spacing: 2) {
        Image(systemName: "iphone")
        Image(systemName: "applewatch.watchface")
      }

      Text("Setup Required")
        .font(.headline)

      Text("Configure TempStick API key and sensors in the iPhone app")
        .font(.caption)
        .multilineTextAlignment(.center)
        .foregroundColor(.secondary)

      Button("Request Sync") {
        watchModel.requestSyncFromiPhone()
      }
      .buttonStyle(.borderedProminent)
    }
    .padding()
  }
}
