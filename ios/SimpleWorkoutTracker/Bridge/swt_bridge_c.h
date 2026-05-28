#ifndef SWT_BRIDGE_C_H
#define SWT_BRIDGE_C_H

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
} SwtExercise;

typedef struct {
    int64_t id;
    char name[256];
    char started_at[32];
    char finished_at[32];
    char notes[512];
    int set_count;
} SwtWorkout;

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
} SwtWorkoutSet;

typedef struct {
    int64_t exercise_id;
    double estimated_1rm;
    double best_weight;
    double total_volume;
    int session_count;
} SwtExerciseStats;

typedef struct {
    char date[32];
    double estimated_1rm;
    double best_set_weight;
    double session_volume;
} SwtProgressionPoint;

typedef struct {
    int64_t id;
    char name[256];
    char notes[512];
    int set_count;
} SwtWorkoutTemplate;

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
} SwtTemplateSet;

typedef struct {
    int new_exercises;
    int existing_exercises;
    int workouts;
    int workout_sets;
    int templates;
    int template_sets;
} SwtImportSummary;

// Lifecycle
void swt_init(const char* db_path);
void swt_close(void);

// Exercises
int64_t swt_add_exercise(const char* name, const char* category, const char* muscle_group, const char* notes);
int swt_list_exercises(const char* filter, SwtExercise* out, int max_count);
void swt_update_exercise(int64_t id, const char* name, const char* category, const char* muscle_group, const char* notes);
void swt_delete_exercise(int64_t id);

// Workouts
int64_t swt_start_workout(const char* name);
void swt_finish_workout(int64_t id);
int swt_get_active_workout(SwtWorkout* out);
int swt_list_workouts(int limit, int offset, SwtWorkout* out, int max_count);
void swt_delete_workout(int64_t id);

// Sets
int64_t swt_add_set(int64_t workout_id, int64_t exercise_id, int order, int reps, double weight, double rpe, int duration_secs, int rest_secs);
int swt_get_sets_for_workout(int64_t workout_id, SwtWorkoutSet* out, int max_count);
void swt_update_set(int64_t id, int reps, double weight, double rpe, int duration_secs, int rest_secs);
void swt_delete_set(int64_t id);

// Stats
int swt_get_stats(int64_t exercise_id, SwtExerciseStats* out);
int swt_get_progression(int64_t exercise_id, int sessions, SwtProgressionPoint* out, int max_count);

// Templates
int64_t swt_create_template(const char* name, const char* notes);
int swt_list_templates(SwtWorkoutTemplate* out, int max_count);
int swt_get_template_sets(int64_t template_id, SwtTemplateSet* out, int max_count);
void swt_delete_template(int64_t id);
int64_t swt_add_template_set(int64_t template_id, int64_t exercise_id, int order, int reps, double weight, double rpe, int duration_secs, int rest_secs);
void swt_delete_template_set(int64_t id);
void swt_swap_template_set_order(int64_t id_a, int order_a, int64_t id_b, int order_b);
int64_t swt_start_workout_from_template(int64_t template_id, const char* name);

// Weight conversion
double swt_to_display_weight(double stored_kg, const char* unit);
double swt_to_storage_weight(double display_value, const char* unit);

// Settings
const char* swt_get_weight_unit(void);
void swt_set_weight_unit(const char* unit);
double swt_get_one_rep_max(int64_t exercise_id);
void swt_set_one_rep_max(int64_t exercise_id, double weight);
int swt_is_setup_complete(void);
void swt_set_setup_complete(int complete);

// Defaults
void swt_seed_default_exercises(void);
void swt_seed_default_templates(void);

// Export/Import
const char* swt_export_to_json(void);
void swt_free_string(const char* str);
int swt_preview_import(const char* json, SwtImportSummary* out);
const char* swt_import_from_json(const char* json);

#ifdef __cplusplus
}
#endif

#endif
