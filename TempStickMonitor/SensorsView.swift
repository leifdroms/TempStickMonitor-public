import SwiftUI

struct SensorsView: View {
    @Environment(AppModel.self) private var appModel
    
    var body: some View {
        NavigationStack {
            List {
                if appModel.isLoading {
                    HStack {
                        ProgressView()
                        Text("Loading TempStick sensors...")
                    }
                    .padding()
                }
                
                if let errorMessage = appModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                }
                
                ForEach(appModel.sensors) { sensor in
                    SensorRowView(
                        sensor: sensor,
                        reading: appModel.currentReadings[sensor.sensorId]
                    )
                }
            }
            .navigationTitle("TempStick Sensors")
            .refreshable {
                await appModel.fetchSensors()
            }
            .task {
                await appModel.fetchSensors()
            }
        }
    }
}
