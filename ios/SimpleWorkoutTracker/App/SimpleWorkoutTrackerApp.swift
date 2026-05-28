import SwiftUI

@main
struct SimpleWorkoutTrackerApp: App {
    init() {
        SwtBridge.shared.initialize()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
