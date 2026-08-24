package com.timsippell.owt.ui.screens

import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.combinedClickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import androidx.navigation.NavController
import com.timsippell.owt.bridge.OwtBridge
import com.timsippell.owt.ui.components.EditSetDialog

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun WorkoutScreen(navController: NavController) {
    val context = LocalContext.current
    val weightUnit = remember { AppSettings.getWeightUnit(context) }
    val restored = remember { OwtBridge.getActiveWorkout() }
    var activeWorkoutId by remember { mutableStateOf(restored?.id) }
    var sets by remember { mutableStateOf(
        restored?.let { OwtBridge.getSetsForWorkout(it.id) } ?: emptyList()
    ) }
    var exercises by remember { mutableStateOf(OwtBridge.listExercises()) }
    var showAddSet by remember { mutableStateOf(false) }
    var showTemplatePicker by remember { mutableStateOf(false) }
    var editingSet by remember { mutableStateOf<OwtBridge.WorkoutSet?>(null) }
    var completedSets by remember { mutableStateOf(setOf<Long>()) }
    var showCancelDialog by remember { mutableStateOf(false) }
    var showFinishDialog by remember { mutableStateOf(false) }

    fun refreshSets() {
        activeWorkoutId?.let { sets = OwtBridge.getSetsForWorkout(it) }
    }

    var showActive by remember { mutableStateOf(activeWorkoutId != null) }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(if (showActive && activeWorkoutId != null) "Active Workout" else "Workout") },
                navigationIcon = {
                    if (showActive && activeWorkoutId != null) {
                        IconButton(onClick = { showActive = false }) {
                            Icon(Icons.Default.Close, contentDescription = "Back")
                        }
                    }
                },
                actions = {
                    if (showActive && activeWorkoutId != null) {
                        TextButton(onClick = { showCancelDialog = true }) {
                            Icon(Icons.Default.Delete, contentDescription = null)
                            Spacer(Modifier.width(4.dp))
                            Text("Cancel")
                        }
                        TextButton(onClick = {
                            if (sets.isNotEmpty() && completedSets.size < sets.size) {
                                showFinishDialog = true
                            } else {
                                OwtBridge.finishWorkout(activeWorkoutId!!)
                                activeWorkoutId = null
                                sets = emptyList()
                                completedSets = emptySet()
                                showActive = false
                            }
                        }) {
                            Icon(Icons.Default.Check, contentDescription = null)
                            Spacer(Modifier.width(4.dp))
                            Text("Finish")
                        }
                    }
                }
            )
        },
        floatingActionButton = {
            if (showActive && activeWorkoutId != null) {
                FloatingActionButton(onClick = { showAddSet = true }) {
                    Icon(Icons.Default.Add, contentDescription = "Add set")
                }
            }
        }
    ) { padding ->
        Column(
            modifier = Modifier.fillMaxSize().padding(padding).padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            if (!showActive || activeWorkoutId == null) {
                if (activeWorkoutId != null) {
                    Button(
                        onClick = {
                            exercises = OwtBridge.listExercises()
                            refreshSets()
                            showActive = true
                        },
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Icon(Icons.Default.PlayArrow, contentDescription = null)
                        Spacer(Modifier.width(8.dp))
                        Text("Continue Workout")
                    }

                    Spacer(Modifier.height(8.dp))
                } else {
                    Button(
                        onClick = {
                            activeWorkoutId = OwtBridge.startWorkout("")
                            exercises = OwtBridge.listExercises()
                            showActive = true
                        },
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Icon(Icons.Default.PlayArrow, contentDescription = null)
                        Spacer(Modifier.width(8.dp))
                        Text("Start Blank Workout")
                    }

                    OutlinedButton(
                        onClick = { showTemplatePicker = true },
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Icon(Icons.Default.PlayArrow, contentDescription = null)
                        Spacer(Modifier.width(8.dp))
                        Text("Start from Template")
                    }

                    Spacer(Modifier.height(8.dp))
                }

                TextButton(
                    onClick = { navController.navigate("templates") },
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Text("Manage Templates")
                }
            } else {
                LazyColumn(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    items(sets) { set ->
                        SetCard(
                            set = set,
                            exercises = exercises,
                            weightUnit = weightUnit,
                            completed = set.id in completedSets,
                            onClick = {
                                completedSets = if (set.id in completedSets)
                                    completedSets - set.id
                                else
                                    completedSets + set.id
                            },
                            onLongClick = { editingSet = set }
                        )
                    }
                    if (sets.isEmpty()) {
                        item {
                            Text(
                                "No sets yet. Tap + to log a set.",
                                style = MaterialTheme.typography.bodyLarge,
                                modifier = Modifier.padding(16.dp)
                            )
                        }
                    }
                }
            }
        }
    }

    if (showCancelDialog) {
        AlertDialog(
            onDismissRequest = { showCancelDialog = false },
            title = { Text("Cancel Workout") },
            text = { Text("This will delete the workout and all its sets. Are you sure?") },
            confirmButton = {
                TextButton(onClick = {
                    activeWorkoutId?.let { OwtBridge.deleteWorkout(it) }
                    activeWorkoutId = null
                    sets = emptyList()
                    completedSets = emptySet()
                    showActive = false
                    showCancelDialog = false
                },
                colors = ButtonDefaults.textButtonColors(
                    contentColor = MaterialTheme.colorScheme.error
                )) { Text("Delete") }
            },
            dismissButton = {
                TextButton(onClick = { showCancelDialog = false }) { Text("Keep") }
            }
        )
    }

    if (showFinishDialog) {
        val incomplete = sets.size - completedSets.size
        AlertDialog(
            onDismissRequest = { showFinishDialog = false },
            title = { Text("Incomplete Workout") },
            text = { Text("$incomplete of ${sets.size} sets not completed. Finish anyway?") },
            confirmButton = {
                TextButton(onClick = {
                    OwtBridge.finishWorkout(activeWorkoutId!!)
                    activeWorkoutId = null
                    sets = emptyList()
                    completedSets = emptySet()
                    showActive = false
                    showFinishDialog = false
                }) { Text("Finish") }
            },
            dismissButton = {
                TextButton(onClick = { showFinishDialog = false }) { Text("Continue") }
            }
        )
    }

    if (showAddSet && activeWorkoutId != null) {
        AddSetDialog(
            exercises = exercises,
            onDismiss = { showAddSet = false },
            onConfirm = { exerciseId, reps, weight, rpe, durationSecs, restSecs ->
                OwtBridge.addSet(activeWorkoutId!!, exerciseId, sets.size + 1, reps, AppSettings.toStorageWeight(weight, context), rpe, durationSecs, restSecs)
                exercises = OwtBridge.listExercises()
                refreshSets()
                showAddSet = false
            }
        )
    }

    if (showTemplatePicker) {
        TemplatePickerDialog(
            onDismiss = { showTemplatePicker = false },
            onSelect = { templateId ->
                activeWorkoutId = OwtBridge.startWorkoutFromTemplate(templateId)
                exercises = OwtBridge.listExercises()
                refreshSets()
                showTemplatePicker = false
                showActive = true
            }
        )
    }

    editingSet?.let { set ->
        EditSetDialog(
            set = set,
            exercises = exercises,
            onDismiss = { editingSet = null },
            onConfirm = { reps, weight, rpe, durationSecs, restSecs ->
                OwtBridge.updateSet(set.id, reps, AppSettings.toStorageWeight(weight, context), rpe, durationSecs, restSecs)
                refreshSets()
                editingSet = null
            }
        )
    }
}

@OptIn(ExperimentalFoundationApi::class)
@Composable
private fun SetCard(
    set: OwtBridge.WorkoutSet,
    exercises: List<OwtBridge.Exercise>,
    weightUnit: String,
    completed: Boolean,
    onClick: () -> Unit,
    onLongClick: () -> Unit
) {
    val context = LocalContext.current
    val exercise = exercises.find { it.id == set.exerciseId }
    val exerciseName = exercise?.name ?: "Unknown"
    val displayWeight = AppSettings.toDisplayWeight(set.weight, context)

    val cardColors = when {
        completed -> CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.primaryContainer
        )
        set.weight == 0.0 && set.durationSecs == 0 -> CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.secondaryContainer
        )
        else -> CardDefaults.cardColors()
    }

    Card(
        modifier = Modifier.fillMaxWidth().combinedClickable(
            onClick = onClick,
            onLongClick = onLongClick
        ),
        colors = cardColors
    ) {
        Row(modifier = Modifier.padding(16.dp), verticalAlignment = Alignment.CenterVertically) {
            Column(modifier = Modifier.weight(1f)) {
                Text(exerciseName, style = MaterialTheme.typography.titleSmall)
                Text(
                    buildString {
                        if (set.reps > 0) append("${set.reps} reps")
                        if (set.weight > 0) append(" × ${"%.1f".format(displayWeight)} $weightUnit")
                        if (set.durationSecs > 0) { if (isNotEmpty()) append(" • "); append("${set.durationSecs}s") }
                        if (set.restSecs > 0) { if (isNotEmpty()) append(" • "); append("rest ${set.restSecs}s") }
                        if (set.rpe > 0) append(" @RPE ${set.rpe}")
                    },
                    style = MaterialTheme.typography.bodyMedium
                )
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun AddSetDialog(
    exercises: List<OwtBridge.Exercise>,
    onDismiss: () -> Unit,
    onConfirm: (Long, Int, Double, Double, Int, Int) -> Unit
) {
    val context = LocalContext.current
    val weightUnit = remember { AppSettings.getWeightUnit(context) }
    var exerciseName by remember { mutableStateOf("") }
    var reps by remember { mutableStateOf("") }
    var weight by remember { mutableStateOf("") }
    var duration by remember { mutableStateOf("") }
    var rest by remember { mutableStateOf("") }
    var rpe by remember { mutableStateOf("") }
    var expanded by remember { mutableStateOf(false) }

    val suggestions = remember(exerciseName) {
        if (exerciseName.isBlank()) emptyList()
        else exercises.filter { it.name.contains(exerciseName, ignoreCase = true) }
    }

    val matchedExercise = remember(exerciseName) {
        exercises.find { it.name.equals(exerciseName, ignoreCase = true) }
    }

    fun resolveExerciseId(): Long {
        if (matchedExercise != null) return matchedExercise.id
        return OwtBridge.addExercise(exerciseName, "", "", "weight")
    }

    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("Log Set") },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                ExposedDropdownMenuBox(
                    expanded = expanded && suggestions.isNotEmpty(),
                    onExpandedChange = { expanded = it }
                ) {
                    OutlinedTextField(
                        value = exerciseName,
                        onValueChange = { exerciseName = it; expanded = true },
                        modifier = Modifier.menuAnchor(MenuAnchorType.PrimaryEditable),
                        label = { Text("Exercise") },
                        singleLine = true
                    )
                    ExposedDropdownMenu(
                        expanded = expanded && suggestions.isNotEmpty(),
                        onDismissRequest = { expanded = false }
                    ) {
                        suggestions.forEach { ex ->
                            DropdownMenuItem(
                                text = { Text(ex.name) },
                                onClick = {
                                    exerciseName = ex.name
                                    expanded = false
                                }
                            )
                        }
                    }
                }
                OutlinedTextField(value = reps, onValueChange = { reps = it }, label = { Text("Reps") }, keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number))
                OutlinedTextField(value = weight, onValueChange = { weight = it }, label = { Text("Weight ($weightUnit)") }, keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal))
                OutlinedTextField(value = duration, onValueChange = { duration = it }, label = { Text("Duration (secs)") }, keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number))
                OutlinedTextField(value = rest, onValueChange = { rest = it }, label = { Text("Rest (secs)") }, keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number))
                OutlinedTextField(value = rpe, onValueChange = { rpe = it }, label = { Text("RPE (optional)") }, keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal))
            }
        },
        confirmButton = {
            TextButton(
                onClick = {
                    val id = resolveExerciseId()
                    onConfirm(id, reps.toIntOrNull() ?: 0, weight.toDoubleOrNull() ?: 0.0, rpe.toDoubleOrNull() ?: 0.0, duration.toIntOrNull() ?: 0, rest.toIntOrNull() ?: 0)
                },
                enabled = exerciseName.isNotBlank()
            ) { Text("Add") }
        },
        dismissButton = { TextButton(onClick = onDismiss) { Text("Cancel") } }
    )
}

@Composable
private fun TemplatePickerDialog(
    onDismiss: () -> Unit,
    onSelect: (Long) -> Unit
) {
    var templates by remember { mutableStateOf(OwtBridge.listTemplates()) }
    var showSeedPrompt by remember { mutableStateOf(templates.isEmpty()) }

    if (showSeedPrompt) {
        AlertDialog(
            onDismissRequest = onDismiss,
            title = { Text("No Templates") },
            text = { Text("Would you like to add some common workout templates? You can edit or remove them later.") },
            confirmButton = {
                TextButton(onClick = {
                    seedDefaultTemplates()
                    templates = OwtBridge.listTemplates()
                    showSeedPrompt = false
                }) { Text("Add defaults") }
            },
            dismissButton = {
                TextButton(onClick = onDismiss) { Text("Cancel") }
            }
        )
    } else {
        AlertDialog(
            onDismissRequest = onDismiss,
            title = { Text("Choose Template") },
            text = {
                LazyColumn(verticalArrangement = Arrangement.spacedBy(4.dp)) {
                    items(templates) { template ->
                        TextButton(
                            onClick = { onSelect(template.id) },
                            modifier = Modifier.fillMaxWidth()
                        ) {
                            Column(modifier = Modifier.fillMaxWidth()) {
                                Text(template.name, style = MaterialTheme.typography.titleSmall)
                                Text("${template.setCount} sets", style = MaterialTheme.typography.bodySmall)
                            }
                        }
                    }
                }
            },
            confirmButton = {},
            dismissButton = { TextButton(onClick = onDismiss) { Text("Cancel") } }
        )
    }
}
