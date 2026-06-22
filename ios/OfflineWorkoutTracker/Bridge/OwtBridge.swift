import Foundation
import OwtBridgeC

final class OwtBridge {
    static let shared = OwtBridge()
    private init() {}

    func initialize() {
        let supportDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        try? FileManager.default.createDirectory(at: supportDir, withIntermediateDirectories: true)
        let dbPath = supportDir.appendingPathComponent("owt.db").path
        owt_init(dbPath)
    }

    func close() {
        owt_close()
    }

    // MARK: - Exercises

    func addExercise(name: String, category: String, muscleGroup: String, notes: String) -> Int64 {
        return owt_add_exercise(name, category, muscleGroup, notes)
    }

    func listExercises(filter: String = "") -> [Exercise] {
        var buffer = [OwtExercise](repeating: OwtExercise(), count: 500)
        let count = owt_list_exercises(filter, &buffer, 500)
        return (0..<Int(count)).map { Exercise(from: buffer[$0]) }
    }

    func updateExercise(id: Int64, name: String, category: String, muscleGroup: String, notes: String) {
        owt_update_exercise(id, name, category, muscleGroup, notes)
    }

    func deleteExercise(id: Int64) {
        owt_delete_exercise(id)
    }

    // MARK: - Workouts

    func startWorkout(name: String = "") -> Int64 {
        return owt_start_workout(name)
    }

    func finishWorkout(id: Int64) {
        owt_finish_workout(id)
    }

    func getActiveWorkout() -> Workout? {
        var w = OwtWorkout()
        let found = owt_get_active_workout(&w)
        guard found != 0 else { return nil }
        return Workout(from: w)
    }

    func listWorkouts(limit: Int = 20, offset: Int = 0) -> [Workout] {
        var buffer = [OwtWorkout](repeating: OwtWorkout(), count: 200)
        let count = owt_list_workouts(Int32(limit), Int32(offset), &buffer, 200)
        return (0..<Int(count)).map { Workout(from: buffer[$0]) }
    }

    func deleteWorkout(id: Int64) {
        owt_delete_workout(id)
    }

    // MARK: - Sets

    func addSet(workoutId: Int64, exerciseId: Int64, order: Int, reps: Int, weight: Double, rpe: Double, durationSecs: Int = 0, restSecs: Int = 0) -> Int64 {
        return owt_add_set(workoutId, exerciseId, Int32(order), Int32(reps), weight, rpe, Int32(durationSecs), Int32(restSecs))
    }

    func getSetsForWorkout(workoutId: Int64) -> [WorkoutSet] {
        var buffer = [OwtWorkoutSet](repeating: OwtWorkoutSet(), count: 500)
        let count = owt_get_sets_for_workout(workoutId, &buffer, 500)
        return (0..<Int(count)).map { WorkoutSet(from: buffer[$0]) }
    }

    func updateSet(id: Int64, reps: Int, weight: Double, rpe: Double, durationSecs: Int = 0, restSecs: Int = 0) {
        owt_update_set(id, Int32(reps), weight, rpe, Int32(durationSecs), Int32(restSecs))
    }

    func deleteSet(id: Int64) {
        owt_delete_set(id)
    }

    // MARK: - Stats

    func getStats(exerciseId: Int64) -> ExerciseStats? {
        var s = OwtExerciseStats()
        let found = owt_get_stats(exerciseId, &s)
        guard found != 0 else { return nil }
        return ExerciseStats(from: s)
    }

    func getProgression(exerciseId: Int64, sessions: Int = 20) -> [ProgressionPoint] {
        var buffer = [OwtProgressionPoint](repeating: OwtProgressionPoint(), count: 100)
        let count = owt_get_progression(exerciseId, Int32(sessions), &buffer, 100)
        return (0..<Int(count)).map { ProgressionPoint(from: buffer[$0]) }
    }

    // MARK: - Templates

    func createTemplate(name: String, notes: String = "") -> Int64 {
        return owt_create_template(name, notes)
    }

    func listTemplates() -> [WorkoutTemplate] {
        var buffer = [OwtWorkoutTemplate](repeating: OwtWorkoutTemplate(), count: 100)
        let count = owt_list_templates(&buffer, 100)
        return (0..<Int(count)).map { WorkoutTemplate(from: buffer[$0]) }
    }

    func getTemplateSets(templateId: Int64) -> [TemplateSet] {
        var buffer = [OwtTemplateSet](repeating: OwtTemplateSet(), count: 200)
        let count = owt_get_template_sets(templateId, &buffer, 200)
        return (0..<Int(count)).map { TemplateSet(from: buffer[$0]) }
    }

    func deleteTemplate(id: Int64) {
        owt_delete_template(id)
    }

    func addTemplateSet(templateId: Int64, exerciseId: Int64, order: Int, reps: Int, weight: Double, rpe: Double, durationSecs: Int = 0, restSecs: Int = 0) -> Int64 {
        return owt_add_template_set(templateId, exerciseId, Int32(order), Int32(reps), weight, rpe, Int32(durationSecs), Int32(restSecs))
    }

    func deleteTemplateSet(id: Int64) {
        owt_delete_template_set(id)
    }

    func swapTemplateSetOrder(idA: Int64, orderA: Int, idB: Int64, orderB: Int) {
        owt_swap_template_set_order(idA, Int32(orderA), idB, Int32(orderB))
    }

    func startWorkoutFromTemplate(templateId: Int64, name: String = "") -> Int64 {
        return owt_start_workout_from_template(templateId, name)
    }

    // MARK: - Weight Conversion

    func toDisplayWeight(_ storedKg: Double) -> Double {
        return owt_to_display_weight(storedKg, getWeightUnit())
    }

    func toStorageWeight(_ displayValue: Double) -> Double {
        return owt_to_storage_weight(displayValue, getWeightUnit())
    }

    // MARK: - Settings

    func getWeightUnit() -> String {
        return String(cString: owt_get_weight_unit())
    }

    func setWeightUnit(_ unit: String) {
        owt_set_weight_unit(unit)
    }

    func getOneRepMax(exerciseId: Int64) -> Double {
        return owt_get_one_rep_max(exerciseId)
    }

    func setOneRepMax(exerciseId: Int64, weight: Double) {
        owt_set_one_rep_max(exerciseId, weight)
    }

    func isSetupComplete() -> Bool {
        return owt_is_setup_complete() != 0
    }

    func setSetupComplete(_ complete: Bool) {
        owt_set_setup_complete(complete ? 1 : 0)
    }

    // MARK: - Defaults

    func seedDefaultExercises() {
        owt_seed_default_exercises()
    }

    func seedDefaultTemplates() {
        owt_seed_default_templates()
    }

    // MARK: - Export/Import

    func exportToJson() -> String {
        return String(cString: owt_export_to_json())
    }

    func previewImport(json: String) -> ImportSummary? {
        var s = OwtImportSummary()
        let found = owt_preview_import(json, &s)
        guard found != 0 else { return nil }
        return ImportSummary(from: s)
    }

    func importFromJson(json: String) -> String {
        return String(cString: owt_import_from_json(json))
    }
}
