import Foundation
import SwtBridgeC

final class SwtBridge {
    static let shared = SwtBridge()
    private init() {}

    func initialize() {
        let supportDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        try? FileManager.default.createDirectory(at: supportDir, withIntermediateDirectories: true)
        let dbPath = supportDir.appendingPathComponent("swt.db").path
        swt_init(dbPath)
    }

    func close() {
        swt_close()
    }

    // MARK: - Exercises

    func addExercise(name: String, category: String, muscleGroup: String, notes: String) -> Int64 {
        return swt_add_exercise(name, category, muscleGroup, notes)
    }

    func listExercises(filter: String = "") -> [Exercise] {
        var buffer = [SwtExercise](repeating: SwtExercise(), count: 500)
        let count = swt_list_exercises(filter, &buffer, 500)
        return (0..<Int(count)).map { Exercise(from: buffer[$0]) }
    }

    func updateExercise(id: Int64, name: String, category: String, muscleGroup: String, notes: String) {
        swt_update_exercise(id, name, category, muscleGroup, notes)
    }

    func deleteExercise(id: Int64) {
        swt_delete_exercise(id)
    }

    // MARK: - Workouts

    func startWorkout(name: String = "") -> Int64 {
        return swt_start_workout(name)
    }

    func finishWorkout(id: Int64) {
        swt_finish_workout(id)
    }

    func getActiveWorkout() -> Workout? {
        var w = SwtWorkout()
        let found = swt_get_active_workout(&w)
        guard found != 0 else { return nil }
        return Workout(from: w)
    }

    func listWorkouts(limit: Int = 20, offset: Int = 0) -> [Workout] {
        var buffer = [SwtWorkout](repeating: SwtWorkout(), count: 200)
        let count = swt_list_workouts(Int32(limit), Int32(offset), &buffer, 200)
        return (0..<Int(count)).map { Workout(from: buffer[$0]) }
    }

    func deleteWorkout(id: Int64) {
        swt_delete_workout(id)
    }

    // MARK: - Sets

    func addSet(workoutId: Int64, exerciseId: Int64, order: Int, reps: Int, weight: Double, rpe: Double, durationSecs: Int = 0, restSecs: Int = 0) -> Int64 {
        return swt_add_set(workoutId, exerciseId, Int32(order), Int32(reps), weight, rpe, Int32(durationSecs), Int32(restSecs))
    }

    func getSetsForWorkout(workoutId: Int64) -> [WorkoutSet] {
        var buffer = [SwtWorkoutSet](repeating: SwtWorkoutSet(), count: 500)
        let count = swt_get_sets_for_workout(workoutId, &buffer, 500)
        return (0..<Int(count)).map { WorkoutSet(from: buffer[$0]) }
    }

    func updateSet(id: Int64, reps: Int, weight: Double, rpe: Double, durationSecs: Int = 0, restSecs: Int = 0) {
        swt_update_set(id, Int32(reps), weight, rpe, Int32(durationSecs), Int32(restSecs))
    }

    func deleteSet(id: Int64) {
        swt_delete_set(id)
    }

    // MARK: - Stats

    func getStats(exerciseId: Int64) -> ExerciseStats? {
        var s = SwtExerciseStats()
        let found = swt_get_stats(exerciseId, &s)
        guard found != 0 else { return nil }
        return ExerciseStats(from: s)
    }

    func getProgression(exerciseId: Int64, sessions: Int = 20) -> [ProgressionPoint] {
        var buffer = [SwtProgressionPoint](repeating: SwtProgressionPoint(), count: 100)
        let count = swt_get_progression(exerciseId, Int32(sessions), &buffer, 100)
        return (0..<Int(count)).map { ProgressionPoint(from: buffer[$0]) }
    }

    // MARK: - Templates

    func createTemplate(name: String, notes: String = "") -> Int64 {
        return swt_create_template(name, notes)
    }

    func listTemplates() -> [WorkoutTemplate] {
        var buffer = [SwtWorkoutTemplate](repeating: SwtWorkoutTemplate(), count: 100)
        let count = swt_list_templates(&buffer, 100)
        return (0..<Int(count)).map { WorkoutTemplate(from: buffer[$0]) }
    }

    func getTemplateSets(templateId: Int64) -> [TemplateSet] {
        var buffer = [SwtTemplateSet](repeating: SwtTemplateSet(), count: 200)
        let count = swt_get_template_sets(templateId, &buffer, 200)
        return (0..<Int(count)).map { TemplateSet(from: buffer[$0]) }
    }

    func deleteTemplate(id: Int64) {
        swt_delete_template(id)
    }

    func addTemplateSet(templateId: Int64, exerciseId: Int64, order: Int, reps: Int, weight: Double, rpe: Double, durationSecs: Int = 0, restSecs: Int = 0) -> Int64 {
        return swt_add_template_set(templateId, exerciseId, Int32(order), Int32(reps), weight, rpe, Int32(durationSecs), Int32(restSecs))
    }

    func deleteTemplateSet(id: Int64) {
        swt_delete_template_set(id)
    }

    func swapTemplateSetOrder(idA: Int64, orderA: Int, idB: Int64, orderB: Int) {
        swt_swap_template_set_order(idA, Int32(orderA), idB, Int32(orderB))
    }

    func startWorkoutFromTemplate(templateId: Int64, name: String = "") -> Int64 {
        return swt_start_workout_from_template(templateId, name)
    }

    // MARK: - Weight Conversion

    func toDisplayWeight(_ storedKg: Double) -> Double {
        return swt_to_display_weight(storedKg, getWeightUnit())
    }

    func toStorageWeight(_ displayValue: Double) -> Double {
        return swt_to_storage_weight(displayValue, getWeightUnit())
    }

    // MARK: - Settings

    func getWeightUnit() -> String {
        return String(cString: swt_get_weight_unit())
    }

    func setWeightUnit(_ unit: String) {
        swt_set_weight_unit(unit)
    }

    func getOneRepMax(exerciseId: Int64) -> Double {
        return swt_get_one_rep_max(exerciseId)
    }

    func setOneRepMax(exerciseId: Int64, weight: Double) {
        swt_set_one_rep_max(exerciseId, weight)
    }

    func isSetupComplete() -> Bool {
        return swt_is_setup_complete() != 0
    }

    func setSetupComplete(_ complete: Bool) {
        swt_set_setup_complete(complete ? 1 : 0)
    }

    // MARK: - Defaults

    func seedDefaultExercises() {
        swt_seed_default_exercises()
    }

    func seedDefaultTemplates() {
        swt_seed_default_templates()
    }

    // MARK: - Export/Import

    func exportToJson() -> String {
        return String(cString: swt_export_to_json())
    }

    func previewImport(json: String) -> ImportSummary? {
        var s = SwtImportSummary()
        let found = swt_preview_import(json, &s)
        guard found != 0 else { return nil }
        return ImportSummary(from: s)
    }

    func importFromJson(json: String) -> String {
        return String(cString: swt_import_from_json(json))
    }
}
