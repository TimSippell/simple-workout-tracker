import SwtBridgeC

struct WorkoutSet: Identifiable {
    let id: Int64
    var workoutId: Int64
    var exerciseId: Int64
    var order: Int
    var reps: Int
    var weight: Double
    var rpe: Double
    var durationSecs: Int
    var restSecs: Int

    init(from c: SwtWorkoutSet) {
        self.id = c.id
        self.workoutId = c.workout_id
        self.exerciseId = c.exercise_id
        self.order = Int(c.set_order)
        self.reps = Int(c.reps)
        self.weight = c.weight
        self.rpe = c.rpe
        self.durationSecs = Int(c.duration_secs)
        self.restSecs = Int(c.rest_secs)
    }
}
