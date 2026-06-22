#ifndef OWT_BRIDGE_C_H
#define OWT_BRIDGE_C_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct {
    int64_t id;
    char name[256];
    char category[64];
    char muscle_group[64];
    char notes[512];
} OwtExercise;

typedef struct {
    int64_t id;
    char name[256];
    char started_at[32];
    char finished_at[32];
    char notes[512];
    int set_count;
} OwtWorkout;

typedef struct {
    int64_t id;
    int64_t workout_id;
    int64_t exercise_id;
    int set_order;
    int reps;
    double weight;
    double rpe;
    int duration_secs;
    int rest_secs;
} OwtWorkoutSet;

typedef struct {
    int64_t exercise_id;
    double estimated_1rm;
    double best_weight;
    double total_volume;
    int session_count;
} OwtExerciseStats;

typedef struct {
    char date[32];
    double estimated_1rm;
    double best_set_weight;
    double session_volume;
} OwtProgressionPoint;

typedef struct {
    int64_t id;
    char name[256];
    char notes[512];
    int set_count;
} OwtWorkoutTemplate;

typedef struct {
    int64_t id;
    int64_t template_id;
    int64_t exercise_id;
    int set_order;
    int reps;
    double weight;
    double rpe;
    int duration_secs;
    int rest_secs;
} OwtTemplateSet;

typedef struct {
    int new_exercises;
    int existing_exercises;
    int workouts;
    int workout_sets;
    int templates;
    int template_sets;
} OwtImportSummary;

// Lifecycle
void owt_init(const char* db_path);
void owt_close(void);

// Exercises
int64_t owt_add_exercise(const char* name, const char* category, const char* muscle_group, const char* notes);
int owt_list_exercises(const char* filter, OwtExercise* out, int max_count);
void owt_update_exercise(int64_t id, const char* name, const char* category, const char* muscle_group, const char* notes);
void owt_delete_exercise(int64_t id);

// Workouts
int64_t owt_start_workout(const char* name);
void owt_finish_workout(int64_t id);
int owt_get_active_workout(OwtWorkout* out);
int owt_list_workouts(int limit, int offset, OwtWorkout* out, int max_count);
void owt_delete_workout(int64_t id);

// Sets
int64_t owt_add_set(int64_t workout_id, int64_t exercise_id, int order, int reps, double weight, double rpe, int duration_secs, int rest_secs);
int owt_get_sets_for_workout(int64_t workout_id, OwtWorkoutSet* out, int max_count);
void owt_update_set(int64_t id, int reps, double weight, double rpe, int duration_secs, int rest_secs);
void owt_delete_set(int64_t id);

// Stats
int owt_get_stats(int64_t exercise_id, OwtExerciseStats* out);
int owt_get_progression(int64_t exercise_id, int sessions, OwtProgressionPoint* out, int max_count);

// Templates
int64_t owt_create_template(const char* name, const char* notes);
int owt_list_templates(OwtWorkoutTemplate* out, int max_count);
int owt_get_template_sets(int64_t template_id, OwtTemplateSet* out, int max_count);
void owt_delete_template(int64_t id);
int64_t owt_add_template_set(int64_t template_id, int64_t exercise_id, int order, int reps, double weight, double rpe, int duration_secs, int rest_secs);
void owt_delete_template_set(int64_t id);
void owt_swap_template_set_order(int64_t id_a, int order_a, int64_t id_b, int order_b);
int64_t owt_start_workout_from_template(int64_t template_id, const char* name);

// Weight conversion
double owt_to_display_weight(double stored_kg, const char* unit);
double owt_to_storage_weight(double display_value, const char* unit);

// Settings
const char* owt_get_weight_unit(void);
void owt_set_weight_unit(const char* unit);
double owt_get_one_rep_max(int64_t exercise_id);
void owt_set_one_rep_max(int64_t exercise_id, double weight);
int owt_is_setup_complete(void);
void owt_set_setup_complete(int complete);

// Defaults
void owt_seed_default_exercises(void);
void owt_seed_default_templates(void);

// Export/Import
const char* owt_export_to_json(void);
void owt_free_string(const char* str);
int owt_preview_import(const char* json, OwtImportSummary* out);
const char* owt_import_from_json(const char* json);

#ifdef __cplusplus
}
#endif

#endif
