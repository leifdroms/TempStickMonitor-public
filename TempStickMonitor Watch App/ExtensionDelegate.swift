import WatchKit

class ExtensionDelegate: NSObject, WKExtensionDelegate {
  func handle(_ backgroundTasks: Set<WKRefreshBackgroundTask>) {
    for task in backgroundTasks {
      switch task {
      case let backgroundRefreshTask as WKApplicationRefreshBackgroundTask:
        Task {
          defer { backgroundRefreshTask.setTaskCompletedWithSnapshot(false) }
          print("Performing background refresh for TempStick data")

          await WatchModel.shared.fetchAllReadings()

          WatchModel.shared.scheduleBackgroundRefresh()
        }

      case let urlSessionTask as WKURLSessionRefreshBackgroundTask:
        urlSessionTask.setTaskCompletedWithSnapshot(false)

      default:
        task.setTaskCompletedWithSnapshot(false)
      }
    }
  }
}
