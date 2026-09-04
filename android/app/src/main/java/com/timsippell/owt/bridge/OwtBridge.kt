package com.timsippell.owt.bridge

import android.content.Context

object OwtBridge {
    init {
        System.loadLibrary("owt-jni")
    }

    data class Exercise(
        val id: Long,
        val name: String,
        val category: String,
        val muscleGroup: String,
        val notes: String
    )

    data class Workout(
        val id: Long,
        val name: String,
        val startedAt: String,
        val finishedAt: String,
        val notes: String,
        val setCount: Int
    )

    data class WorkoutSet(
        val id: Long,
        val workoutId: Long,
        val exerciseId: Long,
        val order: Int,
        val reps: Int,
        val weight: Double,
        val rpe: Double,
        val durationSecs: Int,
        val restSecs: Int
    )

    data class ExerciseStats(
        val exerciseId: Long,
        val estimated1rm: Double,
        val bestWeight: Double,
        val totalVolume: Double,
        val sessionCount: Int
    )

    data class WorkoutTemplate(
        val id: Long,
        val name: String,
        val notes: String,
        val setCount: Int
    )

    data class TemplateSet(
        val id: Long,
        val templateId: Long,
        val exerciseId: Long,
        val order: Int,
        val reps: Int,
        val weight: Double,
        val rpe: Double,
        val durationSecs: Int,
        val restSecs: Int
    )

    data class ProgressionPoint(
        val date: String,
        val estimated1rm: Double,
        val bestSetWeight: Double,
        val sessionVolume: Double
    )

    data class ImportSummary(
        val newExercises: Int,
        val existingExercises: Int,
        val workouts: Int,
        val workoutSets: Int,
        val templates: Int,
        val templateSets: Int
    )

    fun init(context: Context) {
        val dbPath = context.getDatabasePath("owt.db").absolutePath
        context.getDatabasePath("owt.db").parentFile?.mkdirs()
        nativeInit(dbPath)
    }

    fun close() = nativeClose()

    fun addExercise(name: String, category: String, muscleGroup: String, notes: String): Long =
        nativeAddExercise(name, category, muscleGroup, notes)

    fun listExercises(filter: String = ""): List<Exercise> =
        nativeListExercises(filter)?.toList() ?: emptyList()

    fun updateExercise(id: Long, name: String, category: String, muscleGroup: String, notes: String) =
        nativeUpdateExercise(id, name, category, muscleGroup, notes)

    fun deleteExercise(id: Long) = nativeDeleteExercise(id)

    fun startWorkout(name: String = ""): Long = nativeStartWorkout(name)
    fun finishWorkout(id: Long) = nativeFinishWorkout(id)
    fun getActiveWorkout(): Workout? = nativeGetActiveWorkout()
    fun listWorkouts(limit: Int = 20, offset: Int = 0): List<Workout> =
        nativeListWorkouts(limit, offset)?.toList() ?: emptyList()
    fun deleteWorkout(id: Long) = nativeDeleteWorkout(id)

    fun addSet(workoutId: Long, exerciseId: Long, order: Int, reps: Int, weight: Double, rpe: Double, durationSecs: Int = 0, restSecs: Int = 0): Long =
        nativeAddSet(workoutId, exerciseId, order, reps, weight, rpe, durationSecs, restSecs)
    fun getSetsForWorkout(workoutId: Long): List<WorkoutSet> =
        nativeGetSetsForWorkout(workoutId)?.toList() ?: emptyList()
    fun deleteSet(id: Long) = nativeDeleteSet(id)

    fun updateSet(id: Long, reps: Int, weight: Double, rpe: Double, durationSecs: Int = 0, restSecs: Int = 0) =
        nativeUpdateSet(id, reps, weight, rpe, durationSecs, restSecs)

    fun createTemplate(name: String, notes: String = ""): Long =
        nativeCreateTemplate(name, notes)
    fun listTemplates(): List<WorkoutTemplate> =
        nativeListTemplates()?.toList() ?: emptyList()
    fun getTemplateSets(templateId: Long): List<TemplateSet> =
        nativeGetTemplateSets(templateId)?.toList() ?: emptyList()
    fun updateTemplate(id: Long, name: String, notes: String = "") =
        nativeUpdateTemplate(id, name, notes)
    fun deleteTemplate(id: Long) = nativeDeleteTemplate(id)
    fun addTemplateSet(templateId: Long, exerciseId: Long, order: Int, reps: Int, weight: Double, rpe: Double, durationSecs: Int = 0, restSecs: Int = 0): Long =
        nativeAddTemplateSet(templateId, exerciseId, order, reps, weight, rpe, durationSecs, restSecs)
    fun updateTemplateSet(id: Long, reps: Int, weight: Double, rpe: Double, durationSecs: Int = 0, restSecs: Int = 0) =
        nativeUpdateTemplateSet(id, reps, weight, rpe, durationSecs, restSecs)
    fun deleteTemplateSet(id: Long) = nativeDeleteTemplateSet(id)
    fun swapTemplateSetOrder(idA: Long, orderA: Int, idB: Long, orderB: Int) =
        nativeSwapTemplateSetOrder(idA, orderA, idB, orderB)
    fun startWorkoutFromTemplate(templateId: Long, name: String = ""): Long =
        nativeStartWorkoutFromTemplate(templateId, name)

    fun getStats(exerciseId: Long): ExerciseStats? = nativeGetStats(exerciseId)
    fun getProgression(exerciseId: Long, sessions: Int = 20): List<ProgressionPoint> =
        nativeGetProgression(exerciseId, sessions)?.toList() ?: emptyList()

    // Weight conversion
    fun toDisplayWeight(storedKg: Double, unit: String): Double = nativeToDisplayWeight(storedKg, unit)
    fun toStorageWeight(displayValue: Double, unit: String): Double = nativeToStorageWeight(displayValue, unit)

    // Settings
    fun getWeightUnit(): String = nativeGetWeightUnit()
    fun setWeightUnit(unit: String) = nativeSetWeightUnit(unit)
    fun getOneRepMax(exerciseId: Long): Double = nativeGetOneRepMax(exerciseId)
    fun setOneRepMax(exerciseId: Long, weight: Double) = nativeSetOneRepMax(exerciseId, weight)
    fun isSetupComplete(): Boolean = nativeIsSetupComplete()
    fun setSetupComplete(complete: Boolean) = nativeSetSetupComplete(complete)

    // Defaults
    fun seedDefaultExercises() = nativeSeedDefaultExercises()
    fun seedDefaultTemplates() = nativeSeedDefaultTemplates()

    // Export/Import
    fun exportToJson(): String = nativeExportToJson()
    fun previewImport(json: String): ImportSummary? = nativePreviewImport(json)
    fun importFromJson(json: String): String = nativeImportFromJson(json)

    private external fun nativeInit(dbPath: String)
    private external fun nativeClose()
    private external fun nativeAddExercise(name: String, category: String, muscleGroup: String, notes: String): Long
    private external fun nativeListExercises(filter: String): Array<Exercise>?
    private external fun nativeUpdateExercise(id: Long, name: String, category: String, muscleGroup: String, notes: String)
    private external fun nativeDeleteExercise(id: Long)
    private external fun nativeStartWorkout(name: String): Long
    private external fun nativeFinishWorkout(id: Long)
    private external fun nativeGetActiveWorkout(): Workout?
    private external fun nativeListWorkouts(limit: Int, offset: Int): Array<Workout>?
    private external fun nativeDeleteWorkout(id: Long)
    private external fun nativeAddSet(workoutId: Long, exerciseId: Long, order: Int, reps: Int, weight: Double, rpe: Double, durationSecs: Int, restSecs: Int): Long
    private external fun nativeGetSetsForWorkout(workoutId: Long): Array<WorkoutSet>?
    private external fun nativeDeleteSet(id: Long)
    private external fun nativeUpdateSet(id: Long, reps: Int, weight: Double, rpe: Double, durationSecs: Int, restSecs: Int)
    private external fun nativeCreateTemplate(name: String, notes: String): Long
    private external fun nativeListTemplates(): Array<WorkoutTemplate>?
    private external fun nativeGetTemplateSets(templateId: Long): Array<TemplateSet>?
    private external fun nativeUpdateTemplate(id: Long, name: String, notes: String)
    private external fun nativeDeleteTemplate(id: Long)
    private external fun nativeAddTemplateSet(templateId: Long, exerciseId: Long, order: Int, reps: Int, weight: Double, rpe: Double, durationSecs: Int, restSecs: Int): Long
    private external fun nativeUpdateTemplateSet(id: Long, reps: Int, weight: Double, rpe: Double, durationSecs: Int, restSecs: Int)
    private external fun nativeDeleteTemplateSet(id: Long)
    private external fun nativeSwapTemplateSetOrder(idA: Long, orderA: Int, idB: Long, orderB: Int)
    private external fun nativeStartWorkoutFromTemplate(templateId: Long, name: String): Long
    private external fun nativeGetStats(exerciseId: Long): ExerciseStats?
    private external fun nativeGetProgression(exerciseId: Long, sessions: Int): Array<ProgressionPoint>?
    private external fun nativeToDisplayWeight(storedKg: Double, unit: String): Double
    private external fun nativeToStorageWeight(displayValue: Double, unit: String): Double
    private external fun nativeGetWeightUnit(): String
    private external fun nativeSetWeightUnit(unit: String)
    private external fun nativeGetOneRepMax(exerciseId: Long): Double
    private external fun nativeSetOneRepMax(exerciseId: Long, weight: Double)
    private external fun nativeIsSetupComplete(): Boolean
    private external fun nativeSetSetupComplete(complete: Boolean)
    private external fun nativeSeedDefaultExercises()
    private external fun nativeSeedDefaultTemplates()
    private external fun nativeExportToJson(): String
    private external fun nativePreviewImport(json: String): ImportSummary?
    private external fun nativeImportFromJson(json: String): String
}
