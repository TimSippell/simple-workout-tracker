import SwiftUI

enum Tab: String, CaseIterable {
    case exercises = "Exercises"
    case workout = "Workout"
    case history = "History"
    case progress = "Progress"
    case share = "Share"
    case settings = "Settings"

    var icon: String {
        switch self {
        case .exercises: return "list.bullet"
        case .workout: return "figure.strengthtraining.traditional"
        case .history: return "clock"
        case .progress: return "chart.line.uptrend.xyaxis"
        case .share: return "antenna.radiowaves.left.and.right"
        case .settings: return "gearshape"
        }
    }
}

struct ContentView: View {
    @State private var selectedTab: Tab = .workout
    @State private var showSetup = false
    @State private var showTemplates = false
    @State private var editingTemplateId: Int64?

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                ExercisesView(onNavigateToSetup: { showSetup = true })
            }
            .tabItem { Label(Tab.exercises.rawValue, systemImage: Tab.exercises.icon) }
            .tag(Tab.exercises)

            NavigationStack {
                WorkoutView(
                    onManageTemplates: { showTemplates = true },
                    onEditTemplate: { id in editingTemplateId = id }
                )
            }
            .tabItem { Label(Tab.workout.rawValue, systemImage: Tab.workout.icon) }
            .tag(Tab.workout)

            NavigationStack {
                HistoryView()
            }
            .tabItem { Label(Tab.history.rawValue, systemImage: Tab.history.icon) }
            .tag(Tab.history)

            NavigationStack {
                ProgressView()
            }
            .tabItem { Label(Tab.progress.rawValue, systemImage: Tab.progress.icon) }
            .tag(Tab.progress)

            NavigationStack {
                ShareView()
            }
            .tabItem { Label(Tab.share.rawValue, systemImage: Tab.share.icon) }
            .tag(Tab.share)

            NavigationStack {
                SettingsView(onNavigateToSetup: { showSetup = true })
            }
            .tabItem { Label(Tab.settings.rawValue, systemImage: Tab.settings.icon) }
            .tag(Tab.settings)
        }
        .sheet(isPresented: $showSetup) {
            NavigationStack {
                SetupView(onFinish: { showSetup = false })
            }
        }
        .sheet(isPresented: $showTemplates) {
            NavigationStack {
                TemplatesView(
                    onDismiss: { showTemplates = false },
                    onEditTemplate: { id in editingTemplateId = id }
                )
            }
        }
        .sheet(item: Binding(
            get: { editingTemplateId.map { TemplateId(id: $0) } },
            set: { editingTemplateId = $0?.id }
        )) { wrapper in
            NavigationStack {
                TemplateBuilderView(templateId: wrapper.id, onDismiss: { editingTemplateId = nil })
            }
        }
    }
}

struct TemplateId: Identifiable {
    let id: Int64
}
