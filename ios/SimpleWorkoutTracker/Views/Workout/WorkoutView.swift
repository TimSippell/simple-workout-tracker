import SwiftUI

struct WorkoutView: View {
    var onManageTemplates: () -> Void = {}
    var onEditTemplate: (Int64) -> Void = { _ in }

    @State private var activeWorkoutId: Int64?
    @State private var sets: [WorkoutSet] = []
    @State private var exercises: [Exercise] = []
    @State private var showAddSet = false
    @State private var showTemplatePicker = false
    @State private var editingSet: WorkoutSet?
    @State private var completedSets: Set<Int64> = []
    @State private var showCancelAlert = false
    @State private var showFinishAlert = false
    @State private var showActive = false

    var body: some View {
        Group {
            if showActive, let _ = activeWorkoutId {
                activeWorkoutView
            } else {
                startView
            }
        }
        .navigationTitle(showActive && activeWorkoutId != nil ? "Active Workout" : "Workout")
        .toolbar {
            if showActive && activeWorkoutId != nil {
                ToolbarItem(placement: .cancellationAction) {
                    Button(role: .destructive) { showCancelAlert = true } label: {
                        Label("Cancel", systemImage: "trash")
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button { finishWorkout() } label: {
                        Label("Finish", systemImage: "checkmark")
                    }
                }
            }
        }
        .onAppear { restoreActiveWorkout() }
        .alert("Cancel Workout", isPresented: $showCancelAlert) {
            Button("Delete", role: .destructive) {
                if let id = activeWorkoutId { SwtBridge.shared.deleteWorkout(id: id) }
                resetWorkout()
            }
            Button("Keep", role: .cancel) {}
        } message: {
            Text("This will delete the workout and all its sets. Are you sure?")
        }
        .alert("Incomplete Workout", isPresented: $showFinishAlert) {
            Button("Finish") {
                if let id = activeWorkoutId { SwtBridge.shared.finishWorkout(id: id) }
                resetWorkout()
            }
            Button("Continue", role: .cancel) {}
        } message: {
            let incomplete = sets.count - completedSets.count
            Text("\(incomplete) of \(sets.count) sets not completed. Finish anyway?")
        }
        .sheet(isPresented: $showAddSet) {
            AddSetSheet(exercises: exercises) { exerciseId, reps, weight, rpe, durationSecs, restSecs in
                if let id = activeWorkoutId {
                    _ = SwtBridge.shared.addSet(
                        workoutId: id, exerciseId: exerciseId,
                        order: sets.count + 1, reps: reps,
                        weight: SwtBridge.shared.toStorageWeight(weight),
                        rpe: rpe, durationSecs: durationSecs, restSecs: restSecs
                    )
                    refreshSets()
                    exercises = SwtBridge.shared.listExercises()
                }
            }
        }
        .sheet(item: $editingSet) { set in
            EditSetSheet(set: set, exercises: exercises) { reps, weight, rpe, durationSecs, restSecs in
                SwtBridge.shared.updateSet(
                    id: set.id, reps: reps,
                    weight: SwtBridge.shared.toStorageWeight(weight),
                    rpe: rpe, durationSecs: durationSecs, restSecs: restSecs
                )
                refreshSets()
            }
        }
        .sheet(isPresented: $showTemplatePicker) {
            TemplatePickerSheet { templateId in
                activeWorkoutId = SwtBridge.shared.startWorkoutFromTemplate(templateId: templateId)
                exercises = SwtBridge.shared.listExercises()
                refreshSets()
                showActive = true
            }
        }
    }

    private var startView: some View {
        VStack(spacing: 12) {
            if activeWorkoutId != nil {
                Button {
                    exercises = SwtBridge.shared.listExercises()
                    refreshSets()
                    showActive = true
                } label: {
                    Label("Continue Workout", systemImage: "play.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            } else {
                Button {
                    activeWorkoutId = SwtBridge.shared.startWorkout()
                    exercises = SwtBridge.shared.listExercises()
                    showActive = true
                } label: {
                    Label("Start Blank Workout", systemImage: "play.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                Button {
                    showTemplatePicker = true
                } label: {
                    Label("Start from Template", systemImage: "play")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }

            Button("Manage Templates") { onManageTemplates() }
                .font(.footnote)

            Spacer()
        }
        .padding()
    }

    private var activeWorkoutView: some View {
        List {
            if sets.isEmpty {
                Text("No sets yet. Tap + to log a set.")
                    .foregroundStyle(.secondary)
                    .padding()
            }
            ForEach(sets) { set in
                SetRow(
                    set: set,
                    exercises: exercises,
                    completed: completedSets.contains(set.id)
                )
                .contentShape(Rectangle())
                .onTapGesture {
                    if completedSets.contains(set.id) {
                        completedSets.remove(set.id)
                    } else {
                        completedSets.insert(set.id)
                    }
                }
                .onLongPressGesture { editingSet = set }
            }
        }
        .toolbar {
            ToolbarItem(placement: .bottomBar) {
                Button { showAddSet = true } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title)
                }
            }
        }
    }

    private func restoreActiveWorkout() {
        if let w = SwtBridge.shared.getActiveWorkout() {
            activeWorkoutId = w.id
            exercises = SwtBridge.shared.listExercises()
            refreshSets()
        }
    }

    private func refreshSets() {
        if let id = activeWorkoutId {
            sets = SwtBridge.shared.getSetsForWorkout(workoutId: id)
        }
    }

    private func finishWorkout() {
        if !sets.isEmpty && completedSets.count < sets.count {
            showFinishAlert = true
        } else {
            if let id = activeWorkoutId { SwtBridge.shared.finishWorkout(id: id) }
            resetWorkout()
        }
    }

    private func resetWorkout() {
        activeWorkoutId = nil
        sets = []
        completedSets = []
        showActive = false
    }
}

private struct SetRow: View {
    let set: WorkoutSet
    let exercises: [Exercise]
    let completed: Bool

    var body: some View {
        let exerciseName = exercises.first(where: { $0.id == set.exerciseId })?.name ?? "Unknown"
        let displayWeight = SwtBridge.shared.toDisplayWeight(set.weight)
        let weightUnit = SwtBridge.shared.getWeightUnit()

        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(exerciseName)
                    .font(.subheadline.weight(.medium))
                Text(formatSetDetails(set: set, displayWeight: displayWeight, weightUnit: weightUnit))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if completed {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            }
        }
        .padding(.vertical, 4)
        .listRowBackground(completed ? Color.green.opacity(0.1) : nil)
    }
}

func formatSetDetails(set: WorkoutSet, displayWeight: Double, weightUnit: String) -> String {
    var parts: [String] = []
    if set.reps > 0 { parts.append("\(set.reps) reps") }
    if set.weight > 0 { parts.append(String(format: "%.1f %@", displayWeight, weightUnit)) }
    if set.durationSecs > 0 { parts.append("\(set.durationSecs)s") }
    if set.restSecs > 0 { parts.append("rest \(set.restSecs)s") }
    if set.rpe > 0 { parts.append(String(format: "@RPE %.0f", set.rpe)) }
    return parts.joined(separator: " \u{2022} ")
}

struct AddSetSheet: View {
    let exercises: [Exercise]
    let onAdd: (Int64, Int, Double, Double, Int, Int) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var exerciseName = ""
    @State private var reps = ""
    @State private var weight = ""
    @State private var duration = ""
    @State private var rest = ""
    @State private var rpe = ""

    private var suggestions: [Exercise] {
        guard !exerciseName.isEmpty else { return [] }
        return exercises.filter { $0.name.localizedCaseInsensitiveContains(exerciseName) }
    }

    private var matchedExercise: Exercise? {
        exercises.first(where: { $0.name.caseInsensitiveCompare(exerciseName) == .orderedSame })
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Exercise") {
                    TextField("Exercise name", text: $exerciseName)
                    if !suggestions.isEmpty && matchedExercise == nil {
                        ForEach(suggestions) { ex in
                            Button(ex.name) { exerciseName = ex.name }
                                .foregroundStyle(.primary)
                        }
                    }
                }
                Section("Details") {
                    TextField("Reps", text: $reps)
                        .keyboardType(.numberPad)
                    TextField("Weight (\(SwtBridge.shared.getWeightUnit()))", text: $weight)
                        .keyboardType(.decimalPad)
                    TextField("Duration (secs)", text: $duration)
                        .keyboardType(.numberPad)
                    TextField("Rest (secs)", text: $rest)
                        .keyboardType(.numberPad)
                    TextField("RPE (optional)", text: $rpe)
                        .keyboardType(.decimalPad)
                }
            }
            .navigationTitle("Log Set")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let id: Int64
                        if let matched = matchedExercise {
                            id = matched.id
                        } else {
                            id = SwtBridge.shared.addExercise(name: exerciseName, category: "", muscleGroup: "", notes: "weight")
                        }
                        onAdd(id, Int(reps) ?? 0, Double(weight) ?? 0.0, Double(rpe) ?? 0.0, Int(duration) ?? 0, Int(rest) ?? 0)
                        dismiss()
                    }
                    .disabled(exerciseName.isEmpty)
                }
            }
        }
    }
}

struct EditSetSheet: View {
    let set: WorkoutSet
    let exercises: [Exercise]
    let onSave: (Int, Double, Double, Int, Int) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var reps = ""
    @State private var weight = ""
    @State private var duration = ""
    @State private var rest = ""
    @State private var rpe = ""

    var body: some View {
        let exerciseName = exercises.first(where: { $0.id == set.exerciseId })?.name ?? "Unknown"

        NavigationStack {
            Form {
                TextField("Reps", text: $reps).keyboardType(.numberPad)
                TextField("Weight (\(SwtBridge.shared.getWeightUnit()))", text: $weight).keyboardType(.decimalPad)
                TextField("Duration (secs)", text: $duration).keyboardType(.numberPad)
                TextField("Rest (secs)", text: $rest).keyboardType(.numberPad)
                TextField("RPE (optional)", text: $rpe).keyboardType(.decimalPad)
            }
            .navigationTitle(exerciseName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(Int(reps) ?? 0, Double(weight) ?? 0.0, Double(rpe) ?? 0.0, Int(duration) ?? 0, Int(rest) ?? 0)
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            let displayWeight = SwtBridge.shared.toDisplayWeight(set.weight)
            reps = set.reps > 0 ? "\(set.reps)" : ""
            weight = set.weight > 0 ? String(format: "%.1f", displayWeight) : ""
            duration = set.durationSecs > 0 ? "\(set.durationSecs)" : ""
            rest = set.restSecs > 0 ? "\(set.restSecs)" : ""
            rpe = set.rpe > 0 ? "\(set.rpe)" : ""
        }
    }
}

struct TemplatePickerSheet: View {
    let onSelect: (Int64) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var templates: [WorkoutTemplate] = []
    @State private var showSeedAlert = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(templates) { template in
                    Button {
                        onSelect(template.id)
                        dismiss()
                    } label: {
                        VStack(alignment: .leading) {
                            Text(template.name).font(.headline)
                            Text("\(template.setCount) sets").font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    .foregroundStyle(.primary)
                }
                if templates.isEmpty {
                    Text("No templates available.")
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Choose Template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear {
                templates = SwtBridge.shared.listTemplates()
                if templates.isEmpty { showSeedAlert = true }
            }
            .alert("No Templates", isPresented: $showSeedAlert) {
                Button("Add defaults") {
                    SwtBridge.shared.seedDefaultTemplates()
                    templates = SwtBridge.shared.listTemplates()
                }
                Button("Cancel", role: .cancel) { dismiss() }
            } message: {
                Text("Would you like to add some common workout templates?")
            }
        }
    }
}
