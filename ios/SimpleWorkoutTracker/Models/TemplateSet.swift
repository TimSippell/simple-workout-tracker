import SwtBridgeC

struct TemplateSet: Identifiable {
    let id: Int64
    var templateId: Int64
    var exerciseId: Int64
    var order: Int
    var reps: Int
    var weight: Double
    var rpe: Double
    var durationSecs: Int
    var restSecs: Int

    init(from c: SwtTemplateSet) {
        self.id = c.id
        self.templateId = c.template_id
        self.exerciseId = c.exercise_id
        self.order = Int(c.set_order)
        self.reps = Int(c.reps)
        self.weight = c.weight
        self.rpe = c.rpe
        self.durationSecs = Int(c.duration_secs)
        self.restSecs = Int(c.rest_secs)
    }
}
