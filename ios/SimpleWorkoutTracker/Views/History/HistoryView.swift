import SwiftUI

struct HistoryView: View {
    @State private var workouts: [Workout] = []
    @State private var exercises: [Exercise] = []
    @State private var currentMonth = Calendar.current.dateComponents([.year, .month], from: Date())
    @State private var selectedDate: DateComponents?
    @State private var expandedWorkoutId: Int64?

    private var workoutDates: Set<DateComponents> {
        Set(workouts.compactMap { parseDate($0.startedAt) }
            .map { Calendar.current.dateComponents([.year, .month, .day], from: $0) })
    }

    private var filteredWorkouts: [Workout] {
        guard let sel = selectedDate else { return workouts }
        return workouts.filter {
            guard let d = parseDate($0.startedAt) else { return false }
            let dc = Calendar.current.dateComponents([.year, .month, .day], from: d)
            return dc.year == sel.year && dc.month == sel.month && dc.day == sel.day
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                CalendarCard(
                    currentMonth: $currentMonth,
                    selectedDate: $selectedDate,
                    workoutDates: workoutDates
                )
                .padding(.horizontal, 12)
                .padding(.vertical, 8)

                Divider().padding(.horizontal, 16)

                LazyVStack(spacing: 8) {
                    if filteredWorkouts.isEmpty {
                        Text(selectedDate != nil ? "No workouts on this day." : "No workout history yet.")
                            .foregroundStyle(.secondary)
                            .padding(32)
                    }
                    ForEach(filteredWorkouts) { workout in
                        WorkoutCard(
                            workout: workout,
                            exercises: exercises,
                            isExpanded: expandedWorkoutId == workout.id,
                            onTap: {
                                expandedWorkoutId = expandedWorkoutId == workout.id ? nil : workout.id
                            },
                            onDelete: {
                                SwtBridge.shared.deleteWorkout(id: workout.id)
                                reload()
                            }
                        )
                    }
                }
                .padding(16)
            }
        }
        .navigationTitle("History")
        .onAppear { reload() }
    }

    private func reload() {
        workouts = SwtBridge.shared.listWorkouts()
        exercises = SwtBridge.shared.listExercises()
    }
}

private struct WorkoutCard: View {
    let workout: Workout
    let exercises: [Exercise]
    let isExpanded: Bool
    let onTap: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(workout.name.isEmpty ? "Workout" : workout.name)
                        .font(.headline)
                    Text(workout.startedAt)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(workout.setCount) sets")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button(role: .destructive) { onDelete() } label: {
                    Image(systemName: "trash")
                }
                .buttonStyle(.borderless)
            }
            .contentShape(Rectangle())
            .onTapGesture { onTap() }

            if isExpanded {
                Divider().padding(.vertical, 8)
                WorkoutSetsDetail(workoutId: workout.id, exercises: exercises)
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

private struct WorkoutSetsDetail: View {
    let workoutId: Int64
    let exercises: [Exercise]

    @State private var sets: [WorkoutSet] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if sets.isEmpty {
                Text("No sets recorded").font(.caption).foregroundStyle(.secondary)
            }
            ForEach(sets) { set in
                let name = exercises.first(where: { $0.id == set.exerciseId })?.name ?? "Unknown"
                let displayWeight = SwtBridge.shared.toDisplayWeight(set.weight)
                let weightUnit = SwtBridge.shared.getWeightUnit()
                HStack {
                    Text(name).font(.subheadline)
                    Spacer()
                    Text(formatSetDetails(set: set, displayWeight: displayWeight, weightUnit: weightUnit))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .onAppear {
            sets = SwtBridge.shared.getSetsForWorkout(workoutId: workoutId)
        }
    }
}

private struct CalendarCard: View {
    @Binding var currentMonth: DateComponents
    @Binding var selectedDate: DateComponents?
    let workoutDates: Set<DateComponents>

    private var year: Int { currentMonth.year ?? 2024 }
    private var month: Int { currentMonth.month ?? 1 }

    private var monthName: String {
        let df = DateFormatter()
        df.dateFormat = "MMMM yyyy"
        var dc = DateComponents()
        dc.year = year
        dc.month = month
        dc.day = 1
        if let d = Calendar.current.date(from: dc) { return df.string(from: d) }
        return ""
    }

    private var daysInMonth: Int {
        var dc = DateComponents()
        dc.year = year
        dc.month = month
        dc.day = 1
        guard let d = Calendar.current.date(from: dc),
              let range = Calendar.current.range(of: .day, in: .month, for: d) else { return 30 }
        return range.count
    }

    private var firstWeekday: Int {
        var dc = DateComponents()
        dc.year = year
        dc.month = month
        dc.day = 1
        guard let d = Calendar.current.date(from: dc) else { return 0 }
        let wd = Calendar.current.component(.weekday, from: d)
        return (wd + 5) % 7 // Monday = 0
    }

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Button { changeMonth(-1) } label: { Image(systemName: "chevron.left") }
                Spacer()
                Text(monthName).font(.subheadline.weight(.medium))
                Spacer()
                Button { changeMonth(1) } label: { Image(systemName: "chevron.right") }
            }

            let dayLabels = ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]
            HStack {
                ForEach(dayLabels, id: \.self) { day in
                    Text(day).font(.caption2).frame(maxWidth: .infinity)
                }
            }

            let totalCells = firstWeekday + daysInMonth
            let rows = (totalCells + 6) / 7

            ForEach(0..<rows, id: \.self) { row in
                HStack(spacing: 0) {
                    ForEach(0..<7, id: \.self) { col in
                        let cellIndex = row * 7 + col
                        let dayNum = cellIndex - firstWeekday + 1

                        if dayNum >= 1 && dayNum <= daysInMonth {
                            let dc = makeDC(dayNum)
                            let hasWorkout = workoutDates.contains(dc)
                            let isSelected = selectedDate == dc
                            let isToday = isTodayDC(dc)

                            Button {
                                selectedDate = selectedDate == dc ? nil : dc
                            } label: {
                                VStack(spacing: 2) {
                                    Text("\(dayNum)")
                                        .font(isToday ? .caption.weight(.bold) : .caption2)
                                        .foregroundStyle(isToday ? .blue : .primary)
                                    if hasWorkout {
                                        Circle().fill(.blue).frame(width: 5, height: 5)
                                    } else {
                                        Spacer().frame(height: 5)
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity, minHeight: 36)
                            .background(isSelected ? Color.blue.opacity(0.15) : .clear)
                            .clipShape(Circle())
                        } else {
                            Spacer().frame(maxWidth: .infinity, minHeight: 36)
                        }
                    }
                }
            }
        }
        .padding(12)
        .background(Color(.tertiarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func changeMonth(_ delta: Int) {
        var dc = DateComponents()
        dc.year = year
        dc.month = month
        dc.day = 1
        guard let d = Calendar.current.date(from: dc),
              let next = Calendar.current.date(byAdding: .month, value: delta, to: d) else { return }
        currentMonth = Calendar.current.dateComponents([.year, .month], from: next)
    }

    private func makeDC(_ day: Int) -> DateComponents {
        var dc = DateComponents()
        dc.year = year
        dc.month = month
        dc.day = day
        return dc
    }

    private func isTodayDC(_ dc: DateComponents) -> Bool {
        let today = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        return dc.year == today.year && dc.month == today.month && dc.day == today.day
    }
}

private func parseDate(_ dateStr: String) -> Date? {
    let df = DateFormatter()
    df.dateFormat = "yyyy-MM-dd HH:mm:ss"
    if let d = df.date(from: dateStr) { return d }
    df.dateFormat = "yyyy-MM-dd"
    return df.date(from: String(dateStr.prefix(10)))
}
