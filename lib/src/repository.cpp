#include "owt/repository.h"
#include "owt/calculator.h"
#include <stdexcept>

namespace sf {

namespace {

void bind_optional_int(sqlite3_stmt* stmt, int idx, std::optional<int> val) {
    if (val) sqlite3_bind_int(stmt, idx, *val);
    else sqlite3_bind_null(stmt, idx);
}

void bind_optional_double(sqlite3_stmt* stmt, int idx, std::optional<double> val) {
    if (val) sqlite3_bind_double(stmt, idx, *val);
    else sqlite3_bind_null(stmt, idx);
}

void bind_text(sqlite3_stmt* stmt, int idx, const std::string& val) {
    if (val.empty()) sqlite3_bind_null(stmt, idx);
    else sqlite3_bind_text(stmt, idx, val.c_str(), -1, SQLITE_TRANSIENT);
}

std::string col_text(sqlite3_stmt* stmt, int idx) {
    auto p = sqlite3_column_text(stmt, idx);
    return p ? reinterpret_cast<const char*>(p) : "";
}

std::optional<int> col_optional_int(sqlite3_stmt* stmt, int idx) {
    if (sqlite3_column_type(stmt, idx) == SQLITE_NULL) return std::nullopt;
    return sqlite3_column_int(stmt, idx);
}

std::optional<double> col_optional_double(sqlite3_stmt* stmt, int idx) {
    if (sqlite3_column_type(stmt, idx) == SQLITE_NULL) return std::nullopt;
    return sqlite3_column_double(stmt, idx);
}

struct StmtGuard {
    sqlite3_stmt* stmt = nullptr;
    ~StmtGuard() { if (stmt) sqlite3_finalize(stmt); }
};

} // namespace

Repository::Repository(Database& db) : db_(db) {}

// --- Exercises ---

int64_t Repository::add_exercise(const Exercise& ex) {
    const char* sql = "INSERT INTO exercise (name, category, muscle_group, notes) VALUES (?, ?, ?, ?)";
    sqlite3_stmt* raw = nullptr;
    sqlite3_prepare_v2(db_.handle(), sql, -1, &raw, nullptr);
    StmtGuard stmt{raw};

    sqlite3_bind_text(raw, 1, ex.name.c_str(), -1, SQLITE_TRANSIENT);
    bind_text(raw, 2, ex.category);
    bind_text(raw, 3, ex.muscle_group);
    bind_text(raw, 4, ex.notes);

    if (sqlite3_step(raw) != SQLITE_DONE)
        throw std::runtime_error(std::string("add_exercise: ") + sqlite3_errmsg(db_.handle()));

    return sqlite3_last_insert_rowid(db_.handle());
}

std::optional<Exercise> Repository::get_exercise(int64_t id) {
    const char* sql = "SELECT id, name, category, muscle_group, notes FROM exercise WHERE id = ?";
    sqlite3_stmt* raw = nullptr;
    sqlite3_prepare_v2(db_.handle(), sql, -1, &raw, nullptr);
    StmtGuard stmt{raw};
    sqlite3_bind_int64(raw, 1, id);

    if (sqlite3_step(raw) != SQLITE_ROW) return std::nullopt;

    Exercise ex;
    ex.id = sqlite3_column_int64(raw, 0);
    ex.name = col_text(raw, 1);
    ex.category = col_text(raw, 2);
    ex.muscle_group = col_text(raw, 3);
    ex.notes = col_text(raw, 4);
    return ex;
}

std::optional<Exercise> Repository::find_exercise_by_name(const std::string& name) {
    const char* sql = "SELECT id, name, category, muscle_group, notes FROM exercise WHERE name = ? COLLATE NOCASE";
    sqlite3_stmt* raw = nullptr;
    sqlite3_prepare_v2(db_.handle(), sql, -1, &raw, nullptr);
    StmtGuard stmt{raw};
    sqlite3_bind_text(raw, 1, name.c_str(), -1, SQLITE_TRANSIENT);

    if (sqlite3_step(raw) != SQLITE_ROW) return std::nullopt;

    Exercise ex;
    ex.id = sqlite3_column_int64(raw, 0);
    ex.name = col_text(raw, 1);
    ex.category = col_text(raw, 2);
    ex.muscle_group = col_text(raw, 3);
    ex.notes = col_text(raw, 4);
    return ex;
}

std::vector<Exercise> Repository::list_exercises(const std::string& filter) {
    std::string sql = "SELECT id, name, category, muscle_group, notes FROM exercise";
    if (!filter.empty()) sql += " WHERE name LIKE '%' || ? || '%' COLLATE NOCASE";
    sql += " ORDER BY name";

    sqlite3_stmt* raw = nullptr;
    sqlite3_prepare_v2(db_.handle(), sql.c_str(), -1, &raw, nullptr);
    StmtGuard stmt{raw};

    if (!filter.empty())
        sqlite3_bind_text(raw, 1, filter.c_str(), -1, SQLITE_TRANSIENT);

    std::vector<Exercise> result;
    while (sqlite3_step(raw) == SQLITE_ROW) {
        Exercise ex;
        ex.id = sqlite3_column_int64(raw, 0);
        ex.name = col_text(raw, 1);
        ex.category = col_text(raw, 2);
        ex.muscle_group = col_text(raw, 3);
        ex.notes = col_text(raw, 4);
        result.push_back(std::move(ex));
    }
    return result;
}

void Repository::update_exercise(const Exercise& ex) {
    const char* sql = "UPDATE exercise SET name=?, category=?, muscle_group=?, notes=? WHERE id=?";
    sqlite3_stmt* raw = nullptr;
    sqlite3_prepare_v2(db_.handle(), sql, -1, &raw, nullptr);
    StmtGuard stmt{raw};

    sqlite3_bind_text(raw, 1, ex.name.c_str(), -1, SQLITE_TRANSIENT);
    bind_text(raw, 2, ex.category);
    bind_text(raw, 3, ex.muscle_group);
    bind_text(raw, 4, ex.notes);
    sqlite3_bind_int64(raw, 5, ex.id);
    sqlite3_step(raw);
}

void Repository::delete_exercise(int64_t id) {
    const char* sql = "DELETE FROM exercise WHERE id=?";
    sqlite3_stmt* raw = nullptr;
    sqlite3_prepare_v2(db_.handle(), sql, -1, &raw, nullptr);
    StmtGuard stmt{raw};
    sqlite3_bind_int64(raw, 1, id);
    sqlite3_step(raw);
}

// --- Workouts ---

int64_t Repository::start_workout(const std::string& name) {
    const char* sql = "INSERT INTO workout (name) VALUES (?)";
    sqlite3_stmt* raw = nullptr;
    sqlite3_prepare_v2(db_.handle(), sql, -1, &raw, nullptr);
    StmtGuard stmt{raw};
    bind_text(raw, 1, name);

    if (sqlite3_step(raw) != SQLITE_DONE)
        throw std::runtime_error(std::string("start_workout: ") + sqlite3_errmsg(db_.handle()));

    return sqlite3_last_insert_rowid(db_.handle());
}

void Repository::finish_workout(int64_t workout_id) {
    const char* sql = "UPDATE workout SET finished_at = datetime('now') WHERE id = ?";
    sqlite3_stmt* raw = nullptr;
    sqlite3_prepare_v2(db_.handle(), sql, -1, &raw, nullptr);
    StmtGuard stmt{raw};
    sqlite3_bind_int64(raw, 1, workout_id);
    sqlite3_step(raw);
}

std::optional<Workout> Repository::get_workout(int64_t id) {
    const char* sql = "SELECT id, name, started_at, finished_at, notes FROM workout WHERE id = ?";
    sqlite3_stmt* raw = nullptr;
    sqlite3_prepare_v2(db_.handle(), sql, -1, &raw, nullptr);
    StmtGuard stmt{raw};
    sqlite3_bind_int64(raw, 1, id);

    if (sqlite3_step(raw) != SQLITE_ROW) return std::nullopt;

    Workout w;
    w.id = sqlite3_column_int64(raw, 0);
    w.name = col_text(raw, 1);
    w.started_at = col_text(raw, 2);
    w.finished_at = col_text(raw, 3);
    w.notes = col_text(raw, 4);
    w.sets = get_sets_for_workout(id);
    return w;
}

std::optional<Workout> Repository::get_active_workout() {
    const char* sql = "SELECT id, name, started_at, finished_at, notes FROM workout WHERE finished_at IS NULL ORDER BY started_at DESC LIMIT 1";
    sqlite3_stmt* raw = nullptr;
    sqlite3_prepare_v2(db_.handle(), sql, -1, &raw, nullptr);
    StmtGuard stmt{raw};

    if (sqlite3_step(raw) != SQLITE_ROW) return std::nullopt;

    Workout w;
    w.id = sqlite3_column_int64(raw, 0);
    w.name = col_text(raw, 1);
    w.started_at = col_text(raw, 2);
    w.finished_at = col_text(raw, 3);
    w.notes = col_text(raw, 4);
    w.sets = get_sets_for_workout(w.id);
    return w;
}

std::vector<Workout> Repository::list_workouts(int limit, int offset) {
    const char* sql = "SELECT id, name, started_at, finished_at, notes FROM workout WHERE finished_at IS NOT NULL ORDER BY started_at DESC LIMIT ? OFFSET ?";
    sqlite3_stmt* raw = nullptr;
    sqlite3_prepare_v2(db_.handle(), sql, -1, &raw, nullptr);
    StmtGuard stmt{raw};
    sqlite3_bind_int(raw, 1, limit);
    sqlite3_bind_int(raw, 2, offset);

    std::vector<Workout> result;
    while (sqlite3_step(raw) == SQLITE_ROW) {
        Workout w;
        w.id = sqlite3_column_int64(raw, 0);
        w.name = col_text(raw, 1);
        w.started_at = col_text(raw, 2);
        w.finished_at = col_text(raw, 3);
        w.notes = col_text(raw, 4);
        w.sets = get_sets_for_workout(w.id);
        result.push_back(std::move(w));
    }
    return result;
}

void Repository::update_workout(const Workout& w) {
    const char* sql = "UPDATE workout SET name=?, notes=? WHERE id=?";
    sqlite3_stmt* raw = nullptr;
    sqlite3_prepare_v2(db_.handle(), sql, -1, &raw, nullptr);
    StmtGuard stmt{raw};
    bind_text(raw, 1, w.name);
    bind_text(raw, 2, w.notes);
    sqlite3_bind_int64(raw, 3, w.id);
    sqlite3_step(raw);
}

void Repository::set_workout_timestamps(int64_t id, const std::string& started_at, const std::string& finished_at) {
    const char* sql = "UPDATE workout SET started_at=?, finished_at=? WHERE id=?";
    sqlite3_stmt* raw = nullptr;
    sqlite3_prepare_v2(db_.handle(), sql, -1, &raw, nullptr);
    StmtGuard stmt{raw};
    bind_text(raw, 1, started_at);
    bind_text(raw, 2, finished_at);
    sqlite3_bind_int64(raw, 3, id);
    sqlite3_step(raw);
}

void Repository::delete_workout(int64_t id) {
    const char* sql = "DELETE FROM workout WHERE id=?";
    sqlite3_stmt* raw = nullptr;
    sqlite3_prepare_v2(db_.handle(), sql, -1, &raw, nullptr);
    StmtGuard stmt{raw};
    sqlite3_bind_int64(raw, 1, id);
    sqlite3_step(raw);
}

// --- Sets ---

int64_t Repository::add_set(const WorkoutSet& s) {
    const char* sql = "INSERT INTO workout_set (workout_id, exercise_id, set_order, reps, weight, rpe, rest_secs, duration_secs, tempo, notes) VALUES (?,?,?,?,?,?,?,?,?,?)";
    sqlite3_stmt* raw = nullptr;
    sqlite3_prepare_v2(db_.handle(), sql, -1, &raw, nullptr);
    StmtGuard stmt{raw};

    sqlite3_bind_int64(raw, 1, s.workout_id);
    sqlite3_bind_int64(raw, 2, s.exercise_id);
    sqlite3_bind_int(raw, 3, s.set_order);
    bind_optional_int(raw, 4, s.reps);
    bind_optional_double(raw, 5, s.weight);
    bind_optional_double(raw, 6, s.rpe);
    bind_optional_int(raw, 7, s.rest_secs);
    bind_optional_int(raw, 8, s.duration_secs);
    bind_text(raw, 9, s.tempo);
    bind_text(raw, 10, s.notes);

    if (sqlite3_step(raw) != SQLITE_DONE)
        throw std::runtime_error(std::string("add_set: ") + sqlite3_errmsg(db_.handle()));

    return sqlite3_last_insert_rowid(db_.handle());
}

void Repository::update_set(const WorkoutSet& s) {
    const char* sql = "UPDATE workout_set SET reps=?, weight=?, rpe=?, rest_secs=?, duration_secs=?, tempo=?, notes=? WHERE id=?";
    sqlite3_stmt* raw = nullptr;
    sqlite3_prepare_v2(db_.handle(), sql, -1, &raw, nullptr);
    StmtGuard stmt{raw};

    bind_optional_int(raw, 1, s.reps);
    bind_optional_double(raw, 2, s.weight);
    bind_optional_double(raw, 3, s.rpe);
    bind_optional_int(raw, 4, s.rest_secs);
    bind_optional_int(raw, 5, s.duration_secs);
    bind_text(raw, 6, s.tempo);
    bind_text(raw, 7, s.notes);
    sqlite3_bind_int64(raw, 8, s.id);
    sqlite3_step(raw);
}

void Repository::delete_set(int64_t id) {
    const char* sql = "DELETE FROM workout_set WHERE id=?";
    sqlite3_stmt* raw = nullptr;
    sqlite3_prepare_v2(db_.handle(), sql, -1, &raw, nullptr);
    StmtGuard stmt{raw};
    sqlite3_bind_int64(raw, 1, id);
    sqlite3_step(raw);
}

std::vector<WorkoutSet> Repository::get_sets_for_workout(int64_t workout_id) {
    const char* sql = "SELECT id, workout_id, exercise_id, set_order, reps, weight, rpe, rest_secs, duration_secs, tempo, notes FROM workout_set WHERE workout_id=? ORDER BY set_order";
    sqlite3_stmt* raw = nullptr;
    sqlite3_prepare_v2(db_.handle(), sql, -1, &raw, nullptr);
    StmtGuard stmt{raw};
    sqlite3_bind_int64(raw, 1, workout_id);

    std::vector<WorkoutSet> result;
    while (sqlite3_step(raw) == SQLITE_ROW) {
        WorkoutSet s;
        s.id = sqlite3_column_int64(raw, 0);
        s.workout_id = sqlite3_column_int64(raw, 1);
        s.exercise_id = sqlite3_column_int64(raw, 2);
        s.set_order = sqlite3_column_int(raw, 3);
        s.reps = col_optional_int(raw, 4);
        s.weight = col_optional_double(raw, 5);
        s.rpe = col_optional_double(raw, 6);
        s.rest_secs = col_optional_int(raw, 7);
        s.duration_secs = col_optional_int(raw, 8);
        s.tempo = col_text(raw, 9);
        s.notes = col_text(raw, 10);
        result.push_back(std::move(s));
    }
    return result;
}

std::vector<WorkoutSet> Repository::get_sets_for_exercise(int64_t exercise_id, int limit) {
    const char* sql = "SELECT ws.id, ws.workout_id, ws.exercise_id, ws.set_order, ws.reps, ws.weight, ws.rpe, ws.rest_secs, ws.duration_secs, ws.tempo, ws.notes FROM workout_set ws JOIN workout w ON ws.workout_id = w.id WHERE ws.exercise_id=? ORDER BY w.started_at DESC, ws.set_order LIMIT ?";
    sqlite3_stmt* raw = nullptr;
    sqlite3_prepare_v2(db_.handle(), sql, -1, &raw, nullptr);
    StmtGuard stmt{raw};
    sqlite3_bind_int64(raw, 1, exercise_id);
    sqlite3_bind_int(raw, 2, limit);

    std::vector<WorkoutSet> result;
    while (sqlite3_step(raw) == SQLITE_ROW) {
        WorkoutSet s;
        s.id = sqlite3_column_int64(raw, 0);
        s.workout_id = sqlite3_column_int64(raw, 1);
        s.exercise_id = sqlite3_column_int64(raw, 2);
        s.set_order = sqlite3_column_int(raw, 3);
        s.reps = col_optional_int(raw, 4);
        s.weight = col_optional_double(raw, 5);
        s.rpe = col_optional_double(raw, 6);
        s.rest_secs = col_optional_int(raw, 7);
        s.duration_secs = col_optional_int(raw, 8);
        s.tempo = col_text(raw, 9);
        s.notes = col_text(raw, 10);
        result.push_back(std::move(s));
    }
    return result;
}

// --- Templates ---

int64_t Repository::create_template(const WorkoutTemplate& t) {
    const char* sql = "INSERT INTO workout_template (name, notes) VALUES (?, ?)";
    sqlite3_stmt* raw = nullptr;
    sqlite3_prepare_v2(db_.handle(), sql, -1, &raw, nullptr);
    StmtGuard stmt{raw};

    sqlite3_bind_text(raw, 1, t.name.c_str(), -1, SQLITE_TRANSIENT);
    bind_text(raw, 2, t.notes);

    if (sqlite3_step(raw) != SQLITE_DONE)
        throw std::runtime_error(std::string("create_template: ") + sqlite3_errmsg(db_.handle()));

    return sqlite3_last_insert_rowid(db_.handle());
}

std::optional<WorkoutTemplate> Repository::get_template(int64_t id) {
    const char* sql = "SELECT id, name, notes FROM workout_template WHERE id = ?";
    sqlite3_stmt* raw = nullptr;
    sqlite3_prepare_v2(db_.handle(), sql, -1, &raw, nullptr);
    StmtGuard stmt{raw};
    sqlite3_bind_int64(raw, 1, id);

    if (sqlite3_step(raw) != SQLITE_ROW) return std::nullopt;

    WorkoutTemplate t;
    t.id = sqlite3_column_int64(raw, 0);
    t.name = col_text(raw, 1);
    t.notes = col_text(raw, 2);
    t.sets = get_template_sets(id);
    return t;
}

std::vector<WorkoutTemplate> Repository::list_templates() {
    const char* sql = "SELECT id, name, notes FROM workout_template ORDER BY name";
    sqlite3_stmt* raw = nullptr;
    sqlite3_prepare_v2(db_.handle(), sql, -1, &raw, nullptr);
    StmtGuard stmt{raw};

    std::vector<WorkoutTemplate> result;
    while (sqlite3_step(raw) == SQLITE_ROW) {
        WorkoutTemplate t;
        t.id = sqlite3_column_int64(raw, 0);
        t.name = col_text(raw, 1);
        t.notes = col_text(raw, 2);
        result.push_back(std::move(t));
    }
    return result;
}

void Repository::update_template(const WorkoutTemplate& t) {
    const char* sql = "UPDATE workout_template SET name=?, notes=? WHERE id=?";
    sqlite3_stmt* raw = nullptr;
    sqlite3_prepare_v2(db_.handle(), sql, -1, &raw, nullptr);
    StmtGuard stmt{raw};
    sqlite3_bind_text(raw, 1, t.name.c_str(), -1, SQLITE_TRANSIENT);
    bind_text(raw, 2, t.notes);
    sqlite3_bind_int64(raw, 3, t.id);
    sqlite3_step(raw);
}

void Repository::clear_template_ref(int64_t template_id) {
    const char* sql = "UPDATE workout SET template_id = NULL WHERE template_id = ?";
    sqlite3_stmt* raw = nullptr;
    sqlite3_prepare_v2(db_.handle(), sql, -1, &raw, nullptr);
    StmtGuard stmt{raw};
    sqlite3_bind_int64(raw, 1, template_id);
    sqlite3_step(raw);
}

void Repository::delete_template(int64_t id) {
    const char* sql = "DELETE FROM workout_template WHERE id=?";
    sqlite3_stmt* raw = nullptr;
    sqlite3_prepare_v2(db_.handle(), sql, -1, &raw, nullptr);
    StmtGuard stmt{raw};
    sqlite3_bind_int64(raw, 1, id);
    sqlite3_step(raw);
}

// --- Template Sets ---

int64_t Repository::add_template_set(const TemplateSet& s) {
    const char* sql = "INSERT INTO template_set (template_id, exercise_id, set_order, reps, weight, rpe, rest_secs, duration_secs, tempo, notes) VALUES (?,?,?,?,?,?,?,?,?,?)";
    sqlite3_stmt* raw = nullptr;
    sqlite3_prepare_v2(db_.handle(), sql, -1, &raw, nullptr);
    StmtGuard stmt{raw};

    sqlite3_bind_int64(raw, 1, s.template_id);
    sqlite3_bind_int64(raw, 2, s.exercise_id);
    sqlite3_bind_int(raw, 3, s.set_order);
    bind_optional_int(raw, 4, s.reps);
    bind_optional_double(raw, 5, s.weight);
    bind_optional_double(raw, 6, s.rpe);
    bind_optional_int(raw, 7, s.rest_secs);
    bind_optional_int(raw, 8, s.duration_secs);
    bind_text(raw, 9, s.tempo);
    bind_text(raw, 10, s.notes);

    if (sqlite3_step(raw) != SQLITE_DONE)
        throw std::runtime_error(std::string("add_template_set: ") + sqlite3_errmsg(db_.handle()));

    return sqlite3_last_insert_rowid(db_.handle());
}

void Repository::update_template_set(const TemplateSet& s) {
    const char* sql = "UPDATE template_set SET reps=?, weight=?, rpe=?, rest_secs=?, duration_secs=?, tempo=?, notes=? WHERE id=?";
    sqlite3_stmt* raw = nullptr;
    sqlite3_prepare_v2(db_.handle(), sql, -1, &raw, nullptr);
    StmtGuard stmt{raw};

    bind_optional_int(raw, 1, s.reps);
    bind_optional_double(raw, 2, s.weight);
    bind_optional_double(raw, 3, s.rpe);
    bind_optional_int(raw, 4, s.rest_secs);
    bind_optional_int(raw, 5, s.duration_secs);
    bind_text(raw, 6, s.tempo);
    bind_text(raw, 7, s.notes);
    sqlite3_bind_int64(raw, 8, s.id);
    sqlite3_step(raw);
}

void Repository::delete_template_set(int64_t id) {
    const char* sql = "DELETE FROM template_set WHERE id=?";
    sqlite3_stmt* raw = nullptr;
    sqlite3_prepare_v2(db_.handle(), sql, -1, &raw, nullptr);
    StmtGuard stmt{raw};
    sqlite3_bind_int64(raw, 1, id);
    sqlite3_step(raw);
}

void Repository::swap_template_set_order(int64_t id_a, int order_a, int64_t id_b, int order_b) {
    const char* sql = "UPDATE template_set SET set_order=? WHERE id=?";
    sqlite3_stmt* raw = nullptr;

    sqlite3_prepare_v2(db_.handle(), sql, -1, &raw, nullptr);
    StmtGuard stmt1{raw};
    sqlite3_bind_int(raw, 1, order_b);
    sqlite3_bind_int64(raw, 2, id_a);
    sqlite3_step(raw);

    raw = nullptr;
    sqlite3_prepare_v2(db_.handle(), sql, -1, &raw, nullptr);
    StmtGuard stmt2{raw};
    sqlite3_bind_int(raw, 1, order_a);
    sqlite3_bind_int64(raw, 2, id_b);
    sqlite3_step(raw);
}

std::vector<TemplateSet> Repository::get_template_sets(int64_t template_id) {
    const char* sql = "SELECT id, template_id, exercise_id, set_order, reps, weight, rpe, rest_secs, duration_secs, tempo, notes FROM template_set WHERE template_id=? ORDER BY set_order";
    sqlite3_stmt* raw = nullptr;
    sqlite3_prepare_v2(db_.handle(), sql, -1, &raw, nullptr);
    StmtGuard stmt{raw};
    sqlite3_bind_int64(raw, 1, template_id);

    std::vector<TemplateSet> result;
    while (sqlite3_step(raw) == SQLITE_ROW) {
        TemplateSet s;
        s.id = sqlite3_column_int64(raw, 0);
        s.template_id = sqlite3_column_int64(raw, 1);
        s.exercise_id = sqlite3_column_int64(raw, 2);
        s.set_order = sqlite3_column_int(raw, 3);
        s.reps = col_optional_int(raw, 4);
        s.weight = col_optional_double(raw, 5);
        s.rpe = col_optional_double(raw, 6);
        s.rest_secs = col_optional_int(raw, 7);
        s.duration_secs = col_optional_int(raw, 8);
        s.tempo = col_text(raw, 9);
        s.notes = col_text(raw, 10);
        result.push_back(std::move(s));
    }
    return result;
}

int64_t Repository::start_workout_from_template(int64_t template_id, const std::string& name) {
    auto tmpl = get_template(template_id);
    if (!tmpl) throw std::runtime_error("Template not found");

    std::string workout_name = name.empty() ? tmpl->name : name;
    int64_t workout_id = start_workout(workout_name);

    {
        const char* sql = "UPDATE workout SET template_id = ? WHERE id = ?";
        sqlite3_stmt* raw = nullptr;
        sqlite3_prepare_v2(db_.handle(), sql, -1, &raw, nullptr);
        StmtGuard stmt{raw};
        sqlite3_bind_int64(raw, 1, template_id);
        sqlite3_bind_int64(raw, 2, workout_id);
        sqlite3_step(raw);
    }

    for (const auto& ts : tmpl->sets) {
        WorkoutSet ws;
        ws.workout_id = workout_id;
        ws.exercise_id = ts.exercise_id;
        ws.set_order = ts.set_order;
        ws.reps = ts.reps;
        ws.weight = ts.weight;
        ws.rpe = ts.rpe;
        ws.rest_secs = ts.rest_secs;
        ws.duration_secs = ts.duration_secs;
        ws.tempo = ts.tempo;
        ws.notes = ts.notes;
        add_set(ws);
    }

    return workout_id;
}

std::vector<ProgressionPoint> Repository::get_progression(int64_t exercise_id, int last_n_sessions) {
    const char* sql = R"(
        SELECT date(w.started_at) as session_date,
               ws.reps, ws.weight, ws.rpe
        FROM workout_set ws
        JOIN workout w ON ws.workout_id = w.id
        WHERE ws.exercise_id = ?
        ORDER BY w.started_at DESC, ws.set_order
    )";
    sqlite3_stmt* raw = nullptr;
    sqlite3_prepare_v2(db_.handle(), sql, -1, &raw, nullptr);
    StmtGuard stmt{raw};
    sqlite3_bind_int64(raw, 1, exercise_id);

    struct SessionData {
        std::string date;
        std::vector<WorkoutSet> sets;
    };

    std::vector<SessionData> sessions;
    std::string current_date;

    while (sqlite3_step(raw) == SQLITE_ROW) {
        std::string date = col_text(raw, 0);
        WorkoutSet s;
        s.reps = col_optional_int(raw, 1);
        s.weight = col_optional_double(raw, 2);
        s.rpe = col_optional_double(raw, 3);

        if (date != current_date) {
            if (static_cast<int>(sessions.size()) >= last_n_sessions) break;
            sessions.push_back({date, {}});
            current_date = date;
        }
        sessions.back().sets.push_back(std::move(s));
    }

    std::vector<ProgressionPoint> result;
    for (auto& sd : sessions) {
        ProgressionPoint pp;
        pp.date = sd.date;
        pp.session_volume = calculate_volume(sd.sets);

        double best_1rm = 0.0;
        double best_weight = 0.0;
        for (const auto& s : sd.sets) {
            if (!s.weight || !s.reps) continue;
            double w = *s.weight;
            int r = *s.reps;
            if (w > best_weight) best_weight = w;
            double e1rm = s.rpe ? estimate_1rm_rpe(w, r, *s.rpe) : estimate_1rm(w, r);
            if (e1rm > best_1rm) best_1rm = e1rm;
        }
        pp.estimated_1rm = best_1rm;
        pp.best_set_weight = best_weight;
        result.push_back(std::move(pp));
    }

    return result;
}

// --- Settings ---

std::string Repository::get_setting(const std::string& key, const std::string& default_value) {
    const char* sql = "SELECT value FROM settings WHERE key = ?";
    sqlite3_stmt* raw = nullptr;
    sqlite3_prepare_v2(db_.handle(), sql, -1, &raw, nullptr);
    StmtGuard stmt{raw};
    sqlite3_bind_text(raw, 1, key.c_str(), -1, SQLITE_TRANSIENT);

    if (sqlite3_step(raw) != SQLITE_ROW) return default_value;
    return col_text(raw, 0);
}

void Repository::set_setting(const std::string& key, const std::string& value) {
    const char* sql = "INSERT OR REPLACE INTO settings (key, value) VALUES (?, ?)";
    sqlite3_stmt* raw = nullptr;
    sqlite3_prepare_v2(db_.handle(), sql, -1, &raw, nullptr);
    StmtGuard stmt{raw};
    sqlite3_bind_text(raw, 1, key.c_str(), -1, SQLITE_TRANSIENT);
    sqlite3_bind_text(raw, 2, value.c_str(), -1, SQLITE_TRANSIENT);
    sqlite3_step(raw);
}

std::string Repository::get_weight_unit() {
    return get_setting("weight_unit", "kg");
}

void Repository::set_weight_unit(const std::string& unit) {
    set_setting("weight_unit", unit);
}

double Repository::get_one_rep_max(int64_t exercise_id) {
    auto val = get_setting("1rm_" + std::to_string(exercise_id), "0");
    try { return std::stod(val); }
    catch (...) { return 0.0; }
}

void Repository::set_one_rep_max(int64_t exercise_id, double weight) {
    set_setting("1rm_" + std::to_string(exercise_id), std::to_string(weight));
}

bool Repository::is_setup_complete() {
    return get_setting("setup_complete", "0") == "1";
}

void Repository::set_setup_complete(bool complete) {
    set_setting("setup_complete", complete ? "1" : "0");
}

} // namespace sf
