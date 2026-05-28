import SwtBridgeC

struct ExerciseStats {
    let exerciseId: Int64
    var estimated1rm: Double
    var bestWeight: Double
    var totalVolume: Double
    var sessionCount: Int

    init(from c: SwtExerciseStats) {
        self.exerciseId = c.exercise_id
        self.estimated1rm = c.estimated_1rm
        self.bestWeight = c.best_weight
        self.totalVolume = c.total_volume
        self.sessionCount = Int(c.session_count)
    }
}
