import SwtBridgeC

struct Workout: Identifiable {
    let id: Int64
    var name: String
    var startedAt: String
    var finishedAt: String
    var notes: String
    var setCount: Int

    init(from c: SwtWorkout) {
        self.id = c.id
        self.name = withUnsafePointer(to: c.name) {
            $0.withMemoryRebound(to: CChar.self, capacity: 256) { String(cString: $0) }
        }
        self.startedAt = withUnsafePointer(to: c.started_at) {
            $0.withMemoryRebound(to: CChar.self, capacity: 32) { String(cString: $0) }
        }
        self.finishedAt = withUnsafePointer(to: c.finished_at) {
            $0.withMemoryRebound(to: CChar.self, capacity: 32) { String(cString: $0) }
        }
        self.notes = withUnsafePointer(to: c.notes) {
            $0.withMemoryRebound(to: CChar.self, capacity: 512) { String(cString: $0) }
        }
        self.setCount = Int(c.set_count)
    }
}
