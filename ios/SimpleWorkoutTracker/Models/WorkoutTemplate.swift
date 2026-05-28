import SwtBridgeC

struct WorkoutTemplate: Identifiable {
    let id: Int64
    var name: String
    var notes: String
    var setCount: Int

    init(from c: SwtWorkoutTemplate) {
        self.id = c.id
        self.name = withUnsafePointer(to: c.name) {
            $0.withMemoryRebound(to: CChar.self, capacity: 256) { String(cString: $0) }
        }
        self.notes = withUnsafePointer(to: c.notes) {
            $0.withMemoryRebound(to: CChar.self, capacity: 512) { String(cString: $0) }
        }
        self.setCount = Int(c.set_count)
    }
}
