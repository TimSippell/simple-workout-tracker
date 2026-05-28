import SwtBridgeC

struct Exercise: Identifiable, Hashable {
    let id: Int64
    var name: String
    var category: String
    var muscleGroup: String
    var notes: String

    init(from c: SwtExercise) {
        self.id = c.id
        self.name = withUnsafePointer(to: c.name) {
            $0.withMemoryRebound(to: CChar.self, capacity: 256) { String(cString: $0) }
        }
        self.category = withUnsafePointer(to: c.category) {
            $0.withMemoryRebound(to: CChar.self, capacity: 64) { String(cString: $0) }
        }
        self.muscleGroup = withUnsafePointer(to: c.muscle_group) {
            $0.withMemoryRebound(to: CChar.self, capacity: 64) { String(cString: $0) }
        }
        self.notes = withUnsafePointer(to: c.notes) {
            $0.withMemoryRebound(to: CChar.self, capacity: 512) { String(cString: $0) }
        }
    }

    var trackingType: String {
        notes == "time" ? "time" : "weight"
    }
}
