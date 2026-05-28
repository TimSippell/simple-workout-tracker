import SwiftUI

struct SetupView: View {
    let onFinish: () -> Void

    @State private var exercises: [Exercise] = []
    @State private var values: [Int64: String] = [:]

    var body: some View {
        Group {
            if exercises.isEmpty {
                VStack {
                    Text("No exercises yet. Add exercises first, then come back to set your one rep max.")
                        .foregroundStyle(.secondary)
                        .padding(32)
                    Spacer()
                }
            } else {
                Form {
                    Section {
                        Text("Enter your known or estimated one rep max for each exercise. Leave blank to skip.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    ForEach(exercises) { exercise in
                        HStack {
                            Text(exercise.name)
                            Spacer()
                            TextField(SwtBridge.shared.getWeightUnit(), text: Binding(
                                get: { values[exercise.id] ?? "" },
                                set: { values[exercise.id] = $0 }
                            ))
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        }
                    }
                }
            }
        }
        .navigationTitle("Set Up One Rep Max")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    for (exerciseId, value) in values {
                        let weight = Double(value) ?? 0.0
                        SwtBridge.shared.setOneRepMax(exerciseId: exerciseId, weight: SwtBridge.shared.toStorageWeight(weight))
                    }
                    SwtBridge.shared.setSetupComplete(true)
                    onFinish()
                }
            }
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { onFinish() }
            }
        }
        .onAppear {
            exercises = SwtBridge.shared.listExercises().filter { $0.trackingType != "time" }
            for ex in exercises {
                let stored = SwtBridge.shared.getOneRepMax(exerciseId: ex.id)
                let display = stored > 0 ? SwtBridge.shared.toDisplayWeight(stored) : 0.0
                values[ex.id] = stored > 0 ? String(format: "%.1f", display) : ""
            }
        }
    }
}
