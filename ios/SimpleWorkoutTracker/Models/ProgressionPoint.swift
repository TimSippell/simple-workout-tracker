import SwtBridgeC

struct ProgressionPoint: Identifiable {
    var id: String { date }
    var date: String
    var estimated1rm: Double
    var bestSetWeight: Double
    var sessionVolume: Double

    init(from c: SwtProgressionPoint) {
        self.date = withUnsafePointer(to: c.date) {
            $0.withMemoryRebound(to: CChar.self, capacity: 32) { String(cString: $0) }
        }
        self.estimated1rm = c.estimated_1rm
        self.bestSetWeight = c.best_set_weight
        self.sessionVolume = c.session_volume
    }
}
