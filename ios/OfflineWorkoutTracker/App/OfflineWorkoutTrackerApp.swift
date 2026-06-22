import SwiftUI

@main
struct OfflineWorkoutTrackerApp: App {
    init() {
        OwtBridge.shared.initialize()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
