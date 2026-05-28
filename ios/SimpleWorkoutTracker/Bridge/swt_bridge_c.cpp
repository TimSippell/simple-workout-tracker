#include "swt_bridge_c.h"
#include "swt/swt.h"
#include <sstream>
#include <cstring>

static sf::Database* g_db = nullptr;
static sf::Repository* g_repo = nullptr;
static std::string g_weight_unit_buf;
static std::string g_export_buf;
static std::string g_import_result_buf;

static void copy_str(char* dst, size_t dst_size, const std::string& src) {
    strncpy(dst, src.c_str(), dst_size - 1);
    dst[dst_size - 1] = '\0';
}

extern "C" {

void swt_init(const char* db_path) {
    delete g_repo;
    delete g_db;
    g_db = new sf::Database(db_path);
    g_db->migrate();
    g_repo = new sf::Repository(*g_db);
}

void swt_close(void) {
    delete g_repo;
    delete g_db;
    g_repo = nullptr;
    g_db = nullptr;
}

// --- Exercises ---

int64_t swt_add_exercise(const char* name, const char* category, const char* muscle_group, const char* notes) {
    if (!g_repo) return -1;
    sf::Exercise ex;
    ex.name = name;
    ex.category = category;
    ex.muscle_group = muscle_group;
    ex.notes = notes;
    return g_repo->add_exercise(ex);
}

int swt_list_exercises(const char* filter, SwtExercise* out, int max_count) {
    if (!g_repo) return 0;
    auto exercises = g_repo->list_exercises(filter ? filter : "");
    int count = std::min((int)exercises.size(), max_count);
    for (int i = 0; i < count; i++) {
        out[i].id = exercises[i].id;
        copy_str(out[i].name, sizeof(out[i].name), exercises[i].name);
        copy_str(out[i].category, sizeof(out[i].category), exercises[i].category);
        copy_str(out[i].muscle_group, sizeof(out[i].muscle_group), exercises[i].muscle_group);
        copy_str(out[i].notes, sizeof(out[i].notes), exercises[i].notes);
    }
    return count;
}

void swt_update_exercise(int64_t id, const char* name, const char* category, const char* muscle_group, const char* notes) {
    if (!g_repo) return;
    sf::Exercise ex;
    ex.id = id;
    ex.name = name;
    ex.category = category;
    ex.muscle_group = muscle_group;
    ex.notes = notes;
    g_repo->update_exercise(ex);
}

void swt_delete_exercise(int64_t id) {
    if (g_repo) g_repo->delete_exercise(id);
}

// --- Workouts ---

int64_t swt_start_workout(const char* name) {
    if (!g_repo) return -1;
    return g_repo->start_workout(name ? name : "");
}

void swt_finish_workout(int64_t id) {
    if (g_repo) g_repo->finish_workout(id);
}

int swt_get_active_workout(SwtWorkout* out) {
    if (!g_repo) return 0;
    auto w = g_repo->get_active_workout();
    if (!w) return 0;
    out->id = w->id;
    copy_str(out->name, sizeof(out->name), w->name);
    copy_str(out->started_at, sizeof(out->started_at), w->started_at);
    copy_str(out->finished_at, sizeof(out->finished_at), w->finished_at);
    copy_str(out->notes, sizeof(out->notes), w->notes);
    out->set_count = (int)w->sets.size();
    return 1;
}

int swt_list_workouts(int limit, int offset, SwtWorkout* out, int max_count) {
    if (!g_repo) return 0;
    auto workouts = g_repo->list_workouts(limit, offset);
    int count = std::min((int)workouts.size(), max_count);
    for (int i = 0; i < count; i++) {
        out[i].id = workouts[i].id;
        copy_str(out[i].name, sizeof(out[i].name), workouts[i].name);
        copy_str(out[i].started_at, sizeof(out[i].started_at), workouts[i].started_at);
        copy_str(out[i].finished_at, sizeof(out[i].finished_at), workouts[i].finished_at);
        copy_str(out[i].notes, sizeof(out[i].notes), workouts[i].notes);
        out[i].set_count = (int)workouts[i].sets.size();
    }
    return count;
}

void swt_delete_workout(int64_t id) {
    if (g_repo) g_repo->delete_workout(id);
}

// --- Sets ---

int64_t swt_add_set(int64_t workout_id, int64_t exercise_id, int order, int reps, double weight, double rpe, int duration_secs, int rest_secs) {
    if (!g_repo) return -1;
    sf::WorkoutSet s;
    s.workout_id = workout_id;
    s.exercise_id = exercise_id;
    s.set_order = order;
    if (reps > 0) s.reps = reps;
    if (weight > 0) s.weight = weight;
    if (rpe > 0) s.rpe = rpe;
    if (duration_secs > 0) s.duration_secs = duration_secs;
    if (rest_secs > 0) s.rest_secs = rest_secs;
    return g_repo->add_set(s);
}

int swt_get_sets_for_workout(int64_t workout_id, SwtWorkoutSet* out, int max_count) {
    if (!g_repo) return 0;
    auto sets = g_repo->get_sets_for_workout(workout_id);
    int count = std::min((int)sets.size(), max_count);
    for (int i = 0; i < count; i++) {
        out[i].id = sets[i].id;
        out[i].workout_id = sets[i].workout_id;
        out[i].exercise_id = sets[i].exercise_id;
        out[i].set_order = sets[i].set_order;
        out[i].reps = sets[i].reps.value_or(0);
        out[i].weight = sets[i].weight.value_or(0.0);
        out[i].rpe = sets[i].rpe.value_or(0.0);
        out[i].duration_secs = sets[i].duration_secs.value_or(0);
        out[i].rest_secs = sets[i].rest_secs.value_or(0);
    }
    return count;
}

void swt_update_set(int64_t id, int reps, double weight, double rpe, int duration_secs, int rest_secs) {
    if (!g_repo) return;
    sf::WorkoutSet s;
    s.id = id;
    if (reps > 0) s.reps = reps;
    if (weight > 0) s.weight = weight;
    if (rpe > 0) s.rpe = rpe;
    if (duration_secs > 0) s.duration_secs = duration_secs;
    if (rest_secs > 0) s.rest_secs = rest_secs;
    g_repo->update_set(s);
}

void swt_delete_set(int64_t id) {
    if (g_repo) g_repo->delete_set(id);
}

// --- Stats ---

int swt_get_stats(int64_t exercise_id, SwtExerciseStats* out) {
    if (!g_repo) return 0;
    auto sets = g_repo->get_sets_for_exercise(exercise_id);
    if (sets.empty()) return 0;
    auto stats = sf::compute_stats(exercise_id, sets);
    out->exercise_id = stats.exercise_id;
    out->estimated_1rm = stats.estimated_1rm;
    out->best_weight = stats.best_weight;
    out->total_volume = stats.total_volume;
    out->session_count = stats.session_count;
    return 1;
}

int swt_get_progression(int64_t exercise_id, int sessions, SwtProgressionPoint* out, int max_count) {
    if (!g_repo) return 0;
    auto points = g_repo->get_progression(exercise_id, sessions);
    int count = std::min((int)points.size(), max_count);
    for (int i = 0; i < count; i++) {
        copy_str(out[i].date, sizeof(out[i].date), points[i].date);
        out[i].estimated_1rm = points[i].estimated_1rm;
        out[i].best_set_weight = points[i].best_set_weight;
        out[i].session_volume = points[i].session_volume;
    }
    return count;
}

// --- Templates ---

int64_t swt_create_template(const char* name, const char* notes) {
    if (!g_repo) return -1;
    sf::WorkoutTemplate t;
    t.name = name;
    t.notes = notes ? notes : "";
    return g_repo->create_template(t);
}

int swt_list_templates(SwtWorkoutTemplate* out, int max_count) {
    if (!g_repo) return 0;
    auto templates = g_repo->list_templates();
    for (auto& t : templates) {
        t.sets = g_repo->get_template_sets(t.id);
    }
    int count = std::min((int)templates.size(), max_count);
    for (int i = 0; i < count; i++) {
        out[i].id = templates[i].id;
        copy_str(out[i].name, sizeof(out[i].name), templates[i].name);
        copy_str(out[i].notes, sizeof(out[i].notes), templates[i].notes);
        out[i].set_count = (int)templates[i].sets.size();
    }
    return count;
}

int swt_get_template_sets(int64_t template_id, SwtTemplateSet* out, int max_count) {
    if (!g_repo) return 0;
    auto sets = g_repo->get_template_sets(template_id);
    int count = std::min((int)sets.size(), max_count);
    for (int i = 0; i < count; i++) {
        out[i].id = sets[i].id;
        out[i].template_id = sets[i].template_id;
        out[i].exercise_id = sets[i].exercise_id;
        out[i].set_order = sets[i].set_order;
        out[i].reps = sets[i].reps.value_or(0);
        out[i].weight = sets[i].weight.value_or(0.0);
        out[i].rpe = sets[i].rpe.value_or(0.0);
        out[i].duration_secs = sets[i].duration_secs.value_or(0);
        out[i].rest_secs = sets[i].rest_secs.value_or(0);
    }
    return count;
}

void swt_delete_template(int64_t id) {
    if (g_repo) g_repo->delete_template(id);
}

int64_t swt_add_template_set(int64_t template_id, int64_t exercise_id, int order, int reps, double weight, double rpe, int duration_secs, int rest_secs) {
    if (!g_repo) return -1;
    sf::TemplateSet s;
    s.template_id = template_id;
    s.exercise_id = exercise_id;
    s.set_order = order;
    if (reps > 0) s.reps = reps;
    if (weight > 0) s.weight = weight;
    if (rpe > 0) s.rpe = rpe;
    if (duration_secs > 0) s.duration_secs = duration_secs;
    if (rest_secs > 0) s.rest_secs = rest_secs;
    return g_repo->add_template_set(s);
}

void swt_delete_template_set(int64_t id) {
    if (g_repo) g_repo->delete_template_set(id);
}

void swt_swap_template_set_order(int64_t id_a, int order_a, int64_t id_b, int order_b) {
    if (g_repo) g_repo->swap_template_set_order(id_a, order_a, id_b, order_b);
}

int64_t swt_start_workout_from_template(int64_t template_id, const char* name) {
    if (!g_repo) return -1;
    return g_repo->start_workout_from_template(template_id, name ? name : "");
}

// --- Weight Conversion ---

double swt_to_display_weight(double stored_kg, const char* unit) {
    return sf::to_display_weight(stored_kg, unit);
}

double swt_to_storage_weight(double display_value, const char* unit) {
    return sf::to_storage_weight(display_value, unit);
}

// --- Settings ---

const char* swt_get_weight_unit(void) {
    if (!g_repo) return "kg";
    g_weight_unit_buf = g_repo->get_weight_unit();
    return g_weight_unit_buf.c_str();
}

void swt_set_weight_unit(const char* unit) {
    if (g_repo) g_repo->set_weight_unit(unit);
}

double swt_get_one_rep_max(int64_t exercise_id) {
    if (!g_repo) return 0.0;
    return g_repo->get_one_rep_max(exercise_id);
}

void swt_set_one_rep_max(int64_t exercise_id, double weight) {
    if (g_repo) g_repo->set_one_rep_max(exercise_id, weight);
}

int swt_is_setup_complete(void) {
    if (!g_repo) return 0;
    return g_repo->is_setup_complete() ? 1 : 0;
}

void swt_set_setup_complete(int complete) {
    if (g_repo) g_repo->set_setup_complete(complete != 0);
}

// --- Defaults ---

void swt_seed_default_exercises(void) {
    if (g_repo) sf::seed_default_exercises(*g_repo);
}

void swt_seed_default_templates(void) {
    if (g_repo) sf::seed_default_templates(*g_repo);
}

// --- Export/Import ---

const char* swt_export_to_json(void) {
    if (!g_repo) return "{}";
    std::ostringstream ss;
    sf::export_to_json(*g_repo, ss);
    g_export_buf = ss.str();
    return g_export_buf.c_str();
}

void swt_free_string(const char*) {
    // no-op: strings are owned by static buffers
}

int swt_preview_import(const char* json, SwtImportSummary* out) {
    if (!g_repo) return 0;
    auto summary = sf::preview_import(*g_repo, json);
    out->new_exercises = summary.new_exercises;
    out->existing_exercises = summary.existing_exercises;
    out->workouts = summary.workouts;
    out->workout_sets = summary.workout_sets;
    out->templates = summary.templates;
    out->template_sets = summary.template_sets;
    return 1;
}

const char* swt_import_from_json(const char* json) {
    if (!g_repo) {
        g_import_result_buf = "Error: not initialized";
        return g_import_result_buf.c_str();
    }
    try {
        auto result = sf::import_from_json(*g_repo, json);
        g_import_result_buf = "Imported " + std::to_string(result.workouts) + " workouts, "
            + std::to_string(result.templates) + " templates, "
            + std::to_string(result.sets) + " sets";
    } catch (const std::exception& e) {
        g_import_result_buf = "Import failed: " + std::string(e.what());
    }
    return g_import_result_buf.c_str();
}

} // extern "C"
