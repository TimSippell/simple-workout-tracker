import SwiftUI

struct ProgressView: View {
    @State private var exercises: [Exercise] = []
    @State private var selectedExercise: Exercise?
    @State private var stats: ExerciseStats?
    @State private var progression: [ProgressionPoint] = []

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                exercisePicker

                if let s = stats {
                    statsCard(s)
                }

                if !progression.isEmpty {
                    progressionTable
                }

                if selectedExercise == nil {
                    Text("Select an exercise to view progress.")
                        .foregroundStyle(.secondary)
                        .padding()
                }
            }
            .padding()
        }
        .navigationTitle("Progress")
        .onAppear {
            exercises = SwtBridge.shared.listExercises()
        }
        .onChange(of: selectedExercise?.id) { _ in
            loadStats()
        }
    }

    private var exercisePicker: some View {
        Menu {
            ForEach(exercises) { ex in
                Button(ex.name) { selectedExercise = ex }
            }
        } label: {
            HStack {
                Text(selectedExercise?.name ?? "Select exercise")
                    .foregroundStyle(.primary)
                Spacer()
                Image(systemName: "chevron.up.chevron.down")
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }

    private func statsCard(_ s: ExerciseStats) -> some View {
        let weightUnit = SwtBridge.shared.getWeightUnit()
        return VStack(alignment: .leading, spacing: 4) {
            Text("Stats").font(.headline)
            Text(String(format: "Est. 1RM: %.1f %@", SwtBridge.shared.toDisplayWeight(s.estimated1rm), weightUnit))
            Text(String(format: "Best Weight: %.1f %@", SwtBridge.shared.toDisplayWeight(s.bestWeight), weightUnit))
            Text(String(format: "Total Volume: %.0f %@", SwtBridge.shared.toDisplayWeight(s.totalVolume), weightUnit))
            Text("Sessions: \(s.sessionCount)")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var progressionTable: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Progression").font(.headline)
            ForEach(progression) { point in
                HStack {
                    Text(point.date)
                        .font(.caption)
                    Spacer()
                    Text(String(format: "1RM: %.1f", SwtBridge.shared.toDisplayWeight(point.estimated1rm)))
                        .font(.caption)
                    Spacer()
                    Text(String(format: "Vol: %.0f", SwtBridge.shared.toDisplayWeight(point.sessionVolume)))
                        .font(.caption)
                }
            }
        }
    }

    private func loadStats() {
        guard let ex = selectedExercise else {
            stats = nil
            progression = []
            return
        }
        stats = SwtBridge.shared.getStats(exerciseId: ex.id)
        progression = SwtBridge.shared.getProgression(exerciseId: ex.id)
    }
}
