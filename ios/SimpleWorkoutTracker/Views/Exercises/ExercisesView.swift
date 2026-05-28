import SwiftUI

struct ExercisesView: View {
    var onNavigateToSetup: () -> Void = {}

    @State private var exercises: [Exercise] = []
    @State private var showAddSheet = false
    @State private var editingExercise: Exercise?
    @State private var showSeedAlert = false
    @State private var showSetupAlert = false

    var body: some View {
        List {
            if exercises.isEmpty {
                Text("No exercises yet. Tap + to add one.")
                    .foregroundStyle(.secondary)
                    .padding()
            }
            ForEach(exercises) { exercise in
                ExerciseRow(exercise: exercise)
                    .contentShape(Rectangle())
                    .onTapGesture { editingExercise = exercise }
            }
            .onDelete { indexSet in
                for index in indexSet {
                    SwtBridge.shared.deleteExercise(id: exercises[index].id)
                }
                reload()
            }
        }
        .navigationTitle("Exercises")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showAddSheet = true } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .onAppear { reload() }
        .alert("Get Started", isPresented: $showSeedAlert) {
            Button("Add defaults") {
                SwtBridge.shared.seedDefaultExercises()
                reload()
                if !SwtBridge.shared.isSetupComplete() {
                    showSetupAlert = true
                }
            }
            Button("Start empty", role: .cancel) {}
        } message: {
            Text("Would you like to start with a set of common exercises? You can always add, edit, or remove them later.")
        }
        .alert("Set Up One Rep Max", isPresented: $showSetupAlert) {
            Button("Set up now") { onNavigateToSetup() }
            Button("Skip", role: .cancel) {
                SwtBridge.shared.setSetupComplete(true)
            }
        } message: {
            Text("Would you like to enter your one rep max for each exercise? This helps track your progress.")
        }
        .sheet(isPresented: $showAddSheet) {
            ExerciseFormSheet(title: "Add Exercise") { name, category, muscle, trackingType in
                _ = SwtBridge.shared.addExercise(name: name, category: category, muscleGroup: muscle, notes: trackingType)
                reload()
            }
        }
        .sheet(item: $editingExercise) { exercise in
            ExerciseFormSheet(
                title: "Edit Exercise",
                initialName: exercise.name,
                initialCategory: exercise.category,
                initialMuscle: exercise.muscleGroup,
                initialTrackingType: exercise.trackingType
            ) { name, category, muscle, trackingType in
                SwtBridge.shared.updateExercise(id: exercise.id, name: name, category: category, muscleGroup: muscle, notes: trackingType)
                reload()
            }
        }
    }

    private func reload() {
        exercises = SwtBridge.shared.listExercises()
        if exercises.isEmpty {
            showSeedAlert = true
        }
    }
}

private struct ExerciseRow: View {
    let exercise: Exercise

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(exercise.name)
                .font(.headline)
            HStack(spacing: 4) {
                if !exercise.category.isEmpty {
                    Text("\(exercise.category) \u{2022} \(exercise.muscleGroup)")
                }
                Text("\u{2022} \(exercise.trackingType == "time" ? "Time" : "Weight")")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct ExerciseFormSheet: View {
    let title: String
    var initialName: String = ""
    var initialCategory: String = ""
    var initialMuscle: String = ""
    var initialTrackingType: String = "weight"
    let onSave: (String, String, String, String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name: String = ""
    @State private var category: String = ""
    @State private var muscle: String = ""
    @State private var trackingType: String = "weight"

    var body: some View {
        NavigationStack {
            Form {
                TextField("Name", text: $name)
                TextField("Category", text: $category)
                TextField("Muscle Group", text: $muscle)
                Picker("Tracking Type", selection: $trackingType) {
                    Text("Weight").tag("weight")
                    Text("Time").tag("time")
                }
                .pickerStyle(.segmented)
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(name, category, muscle, trackingType)
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
        .onAppear {
            name = initialName
            category = initialCategory
            muscle = initialMuscle
            trackingType = initialTrackingType
        }
    }
}
