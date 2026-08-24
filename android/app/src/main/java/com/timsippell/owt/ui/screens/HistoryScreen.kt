package com.timsippell.owt.ui.screens

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ChevronLeft
import androidx.compose.material.icons.filled.ChevronRight
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.timsippell.owt.bridge.OwtBridge
import com.timsippell.owt.ui.components.EditSetDialog
import java.time.LocalDate
import java.time.YearMonth
import java.time.format.DateTimeFormatter
import java.time.format.TextStyle
import androidx.compose.ui.platform.LocalContext
import java.util.Locale

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun HistoryScreen() {
    val context = LocalContext.current
    val weightUnit = remember { AppSettings.getWeightUnit(context) }
    var workouts by remember { mutableStateOf(OwtBridge.listWorkouts()) }
    var currentMonth by remember { mutableStateOf(YearMonth.now()) }
    var selectedDate by remember { mutableStateOf<LocalDate?>(null) }
    var editingSet by remember { mutableStateOf<OwtBridge.WorkoutSet?>(null) }
    var setsRevision by remember { mutableStateOf(0) }
    val exercises = remember { OwtBridge.listExercises() }

    val workoutDates = remember(workouts) {
        workouts.mapNotNull { parseDate(it.startedAt) }.toSet()
    }

    val filteredWorkouts = remember(workouts, selectedDate) {
        if (selectedDate == null) workouts
        else workouts.filter { parseDate(it.startedAt) == selectedDate }
    }

    Scaffold(
        topBar = { TopAppBar(title = { Text("History") }) }
    ) { padding ->
        Column(
            modifier = Modifier.fillMaxSize().padding(padding)
        ) {
            CalendarView(
                currentMonth = currentMonth,
                workoutDates = workoutDates,
                selectedDate = selectedDate,
                onMonthChange = { currentMonth = it },
                onDateSelect = { date ->
                    selectedDate = if (selectedDate == date) null else date
                }
            )

            HorizontalDivider(modifier = Modifier.padding(horizontal = 16.dp))

            var expandedWorkoutId by remember { mutableStateOf<Long?>(null) }

            LazyColumn(
                contentPadding = PaddingValues(16.dp),
                verticalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                items(filteredWorkouts, key = { it.id }) { workout ->
                    val isExpanded = expandedWorkoutId == workout.id

                    Card(
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Column(modifier = Modifier.padding(16.dp)) {
                            Row(
                                modifier = Modifier.fillMaxWidth().clickable {
                                    expandedWorkoutId = if (isExpanded) null else workout.id
                                },
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Column(modifier = Modifier.weight(1f)) {
                                    Text(
                                        workout.name.ifEmpty { "Workout" },
                                        style = MaterialTheme.typography.titleMedium
                                    )
                                    Text(
                                        workout.startedAt,
                                        style = MaterialTheme.typography.bodySmall
                                    )
                                    Text(
                                        "${workout.setCount} sets",
                                        style = MaterialTheme.typography.bodySmall
                                    )
                                }
                                IconButton(onClick = {
                                    OwtBridge.deleteWorkout(workout.id)
                                    workouts = OwtBridge.listWorkouts()
                                }) {
                                    Icon(Icons.Default.Delete, contentDescription = "Delete")
                                }
                            }

                            AnimatedVisibility(visible = isExpanded) {
                                val sets = remember(workout.id, setsRevision) {
                                    OwtBridge.getSetsForWorkout(workout.id)
                                }
                                Column(
                                    modifier = Modifier.padding(top = 12.dp),
                                    verticalArrangement = Arrangement.spacedBy(4.dp)
                                ) {
                                    HorizontalDivider()
                                    Spacer(Modifier.height(4.dp))
                                    sets.forEach { set ->
                                        val name = exercises.find { it.id == set.exerciseId }?.name ?: "Unknown"
                                        Row(
                                            modifier = Modifier
                                                .fillMaxWidth()
                                                .clickable { editingSet = set },
                                            horizontalArrangement = Arrangement.SpaceBetween
                                        ) {
                                            Text(name, style = MaterialTheme.typography.bodyMedium)
                                            Text(
                                                buildString {
                                                    if (set.reps > 0) append("${set.reps} reps")
                                                    if (set.weight > 0) append(" × ${"%.1f".format(AppSettings.toDisplayWeight(set.weight, context))} $weightUnit")
                                                    if (set.durationSecs > 0) { if (isNotEmpty()) append(" • "); append("${set.durationSecs}s") }
                                                    if (set.restSecs > 0) { if (isNotEmpty()) append(" • "); append("rest ${set.restSecs}s") }
                                                    if (set.rpe > 0) append(" @${set.rpe}")
                                                },
                                                style = MaterialTheme.typography.bodyMedium
                                            )
                                        }
                                    }
                                    if (sets.isEmpty()) {
                                        Text("No sets recorded", style = MaterialTheme.typography.bodySmall)
                                    }
                                }
                            }
                        }
                    }
                }
                if (filteredWorkouts.isEmpty()) {
                    item {
                        Text(
                            if (selectedDate != null) "No workouts on this day."
                            else "No workout history yet.",
                            modifier = Modifier.padding(32.dp),
                            style = MaterialTheme.typography.bodyLarge
                        )
                    }
                }
            }
        }
    }

    editingSet?.let { set ->
        EditSetDialog(
            set = set,
            exercises = exercises,
            onDismiss = { editingSet = null },
            onConfirm = { reps, weight, rpe, durationSecs, restSecs ->
                OwtBridge.updateSet(set.id, reps, AppSettings.toStorageWeight(weight, context), rpe, durationSecs, restSecs)
                setsRevision++
                editingSet = null
            }
        )
    }
}

@Composable
private fun CalendarView(
    currentMonth: YearMonth,
    workoutDates: Set<LocalDate>,
    selectedDate: LocalDate?,
    onMonthChange: (YearMonth) -> Unit,
    onDateSelect: (LocalDate) -> Unit
) {
    Card(
        modifier = Modifier.fillMaxWidth().padding(horizontal = 12.dp, vertical = 8.dp),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surfaceVariant
        )
    ) {
        Column(modifier = Modifier.padding(12.dp)) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                IconButton(onClick = { onMonthChange(currentMonth.minusMonths(1)) }) {
                    Icon(Icons.Default.ChevronLeft, contentDescription = "Previous month")
                }
                Text(
                    "${currentMonth.month.getDisplayName(TextStyle.FULL, Locale.getDefault())} ${currentMonth.year}",
                    style = MaterialTheme.typography.titleSmall
                )
                IconButton(onClick = { onMonthChange(currentMonth.plusMonths(1)) }) {
                    Icon(Icons.Default.ChevronRight, contentDescription = "Next month")
                }
            }

            Row(modifier = Modifier.fillMaxWidth()) {
                listOf("Mo", "Tu", "We", "Th", "Fr", "Sa", "Su").forEach { day ->
                    Text(
                        day,
                        modifier = Modifier.weight(1f),
                        textAlign = TextAlign.Center,
                        style = MaterialTheme.typography.labelSmall
                    )
                }
            }

            Spacer(Modifier.height(4.dp))

            val firstDay = currentMonth.atDay(1)
            val dayOfWeekOffset = (firstDay.dayOfWeek.value - 1)
            val daysInMonth = currentMonth.lengthOfMonth()
            val totalCells = dayOfWeekOffset + daysInMonth
            val rows = (totalCells + 6) / 7

            for (row in 0 until rows) {
                Row(
                    modifier = Modifier.fillMaxWidth().height(36.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    for (col in 0..6) {
                        val cellIndex = row * 7 + col
                        val dayNum = cellIndex - dayOfWeekOffset + 1

                        if (dayNum in 1..daysInMonth) {
                            val date = currentMonth.atDay(dayNum)
                            val hasWorkout = date in workoutDates
                            val isSelected = date == selectedDate
                            val isToday = date == LocalDate.now()

                            Box(
                                modifier = Modifier
                                    .weight(1f)
                                    .fillMaxHeight()
                                    .clip(CircleShape)
                                    .then(
                                        if (isSelected) Modifier.background(
                                            MaterialTheme.colorScheme.primaryContainer,
                                            CircleShape
                                        )
                                        else Modifier
                                    )
                                    .clickable { onDateSelect(date) },
                                contentAlignment = Alignment.Center
                            ) {
                                Column(horizontalAlignment = Alignment.CenterHorizontally) {
                                    Text(
                                        "$dayNum",
                                        style = if (isToday) MaterialTheme.typography.labelLarge
                                        else MaterialTheme.typography.bodySmall,
                                        color = if (isToday) MaterialTheme.colorScheme.primary
                                        else MaterialTheme.colorScheme.onSurface
                                    )
                                    if (hasWorkout) {
                                        Box(
                                            modifier = Modifier
                                                .size(5.dp)
                                                .background(
                                                    MaterialTheme.colorScheme.primary,
                                                    CircleShape
                                                )
                                        )
                                    }
                                }
                            }
                        } else {
                            Spacer(Modifier.weight(1f))
                        }
                    }
                }
            }
        }
    }
}

internal fun parseDate(dateStr: String): LocalDate? {
    return try {
        val formatter = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss")
        LocalDate.parse(dateStr, formatter)
    } catch (e: Exception) {
        try {
            LocalDate.parse(dateStr.take(10))
        } catch (e: Exception) {
            null
        }
    }
}
