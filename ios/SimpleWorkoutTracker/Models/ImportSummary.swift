import SwtBridgeC

struct ImportSummary {
    var newExercises: Int
    var existingExercises: Int
    var workouts: Int
    var workoutSets: Int
    var templates: Int
    var templateSets: Int

    init(from c: SwtImportSummary) {
        self.newExercises = Int(c.new_exercises)
        self.existingExercises = Int(c.existing_exercises)
        self.workouts = Int(c.workouts)
        self.workoutSets = Int(c.workout_sets)
        self.templates = Int(c.templates)
        self.templateSets = Int(c.template_sets)
    }
}
