package com.timsippell.owt.ui.screens

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.KeyboardArrowUp
import androidx.compose.material.icons.filled.KeyboardArrowDown
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.foundation.clickable
import androidx.compose.ui.unit.dp
import androidx.navigation.NavController
import com.timsippell.owt.bridge.OwtBridge

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun TemplateBuilderScreen(templateId: Long?, navController: NavController) {
    if (templateId == null) return

    val context = LocalContext.current
    var sets by remember { mutableStateOf(OwtBridge.getTemplateSets(templateId)) }
    val exercises = remember { OwtBridge.listExercises() }
    var showAddDialog by remember { mutableStateOf(false) }
    var editingSet by remember { mutableStateOf<OwtBridge.TemplateSet?>(null) }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Edit Template") },
                navigationIcon = {
                    IconButton(onClick = { navController.popBackStack() }) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back")
                    }
                }
            )
        },
        floatingActionButton = {
            FloatingActionButton(onClick = { showAddDialog = true }) {
                Icon(Icons.Default.Add, contentDescription = "Add exercise")
            }
        }
    ) { padding ->
        LazyColumn(
            modifier = Modifier.fillMaxSize().padding(padding),
            contentPadding = PaddingValues(start = 16.dp, end = 16.dp, top = 16.dp, bottom = 80.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            items(sets.size, key = { sets[it].id }) { index ->
                val set = sets[index]
                val exerciseName = exercises.find { it.id == set.exerciseId }?.name ?: "Unknown"
                TemplateSetCard(
                    exerciseName = exerciseName,
                    set = set,
                    isFirst = index == 0,
                    isLast = index == sets.size - 1,
                    onEdit = { editingSet = set },
                    onMoveUp = {
                        val prev = sets[index - 1]
                        OwtBridge.swapTemplateSetOrder(set.id, set.order, prev.id, prev.order)
                        sets = OwtBridge.getTemplateSets(templateId)
                    },
                    onMoveDown = {
                        val next = sets[index + 1]
                        OwtBridge.swapTemplateSetOrder(set.id, set.order, next.id, next.order)
                        sets = OwtBridge.getTemplateSets(templateId)
                    },
                    onDelete = {
                        OwtBridge.deleteTemplateSet(set.id)
                        sets = OwtBridge.getTemplateSets(templateId)
                    }
                )
            }
            if (sets.isEmpty()) {
                item {
                    Text(
                        "No exercises yet. Tap + to add one.",
                        modifier = Modifier.padding(32.dp),
                        style = MaterialTheme.typography.bodyLarge
                    )
                }
            }
        }
    }

    editingSet?.let { set ->
        val exerciseName = exercises.find { it.id == set.exerciseId }?.name ?: "Unknown"
        EditTemplateSetDialog(
            exerciseName = exerciseName,
            set = set,
            onDismiss = { editingSet = null },
            onConfirm = { reps, weight, rpe, durationSecs, restSecs ->
                OwtBridge.updateTemplateSet(
                    set.id, reps,
                    AppSettings.toStorageWeight(weight, context),
                    rpe, durationSecs, restSecs
                )
                sets = OwtBridge.getTemplateSets(templateId)
                editingSet = null
            }
        )
    }

    if (showAddDialog) {
        AddTemplateSetDialog(
            exercises = exercises,
            onDismiss = { showAddDialog = false },
            onConfirm = { exerciseId, numSets, reps, weight, rpe, durationSecs, restSecs ->
                for (i in 1..numSets) {
                    OwtBridge.addTemplateSet(
                        templateId, exerciseId,
                        sets.size + i, reps, AppSettings.toStorageWeight(weight, context), rpe, durationSecs, restSecs
                    )
                }
                sets = OwtBridge.getTemplateSets(templateId)
                showAddDialog = false
            }
        )
    }
}

@Composable
private fun TemplateSetCard(
    exerciseName: String,
    set: OwtBridge.TemplateSet,
    isFirst: Boolean,
    isLast: Boolean,
    onEdit: () -> Unit,
    onMoveUp: () -> Unit,
    onMoveDown: () -> Unit,
    onDelete: () -> Unit
) {
    val context = LocalContext.current
    val weightUnit = remember { AppSettings.getWeightUnit(context) }
    Card(modifier = Modifier.fillMaxWidth().clickable { onEdit() }) {
        Row(
            modifier = Modifier.padding(start = 16.dp, top = 4.dp, bottom = 4.dp, end = 4.dp).fillMaxWidth(),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Column(modifier = Modifier.weight(1f)) {
                Text(exerciseName, style = MaterialTheme.typography.titleSmall)
                Text(
                    buildString {
                        if (set.reps > 0) append("${set.reps} reps")
                        if (set.weight > 0) { if (isNotEmpty()) append(" • "); append("${"%.1f".format(AppSettings.toDisplayWeight(set.weight, context))} $weightUnit") }
                        if (set.durationSecs > 0) { if (isNotEmpty()) append(" • "); append("${set.durationSecs}s") }
                        if (set.restSecs > 0) { if (isNotEmpty()) append(" • "); append("rest ${set.restSecs}s") }
                        if (set.rpe > 0) { if (isNotEmpty()) append(" • "); append("@RPE ${set.rpe}") }
                    },
                    style = MaterialTheme.typography.bodyMedium
                )
            }
            Column {
                IconButton(onClick = onMoveUp, enabled = !isFirst, modifier = Modifier.size(32.dp)) {
                    Icon(Icons.Default.KeyboardArrowUp, contentDescription = "Move up")
                }
                IconButton(onClick = onMoveDown, enabled = !isLast, modifier = Modifier.size(32.dp)) {
                    Icon(Icons.Default.KeyboardArrowDown, contentDescription = "Move down")
                }
            }
            IconButton(onClick = onDelete) {
                Icon(Icons.Default.Delete, contentDescription = "Remove")
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun AddTemplateSetDialog(
    exercises: List<OwtBridge.Exercise>,
    onDismiss: () -> Unit,
    onConfirm: (Long, Int, Int, Double, Double, Int, Int) -> Unit
) {
    val context = LocalContext.current
    val weightUnit = remember { AppSettings.getWeightUnit(context) }
    var selectedExercise by remember { mutableStateOf(exercises.firstOrNull()) }
    var numSets by remember { mutableStateOf("3") }
    var reps by remember { mutableStateOf("") }
    var weight by remember { mutableStateOf("") }
    var duration by remember { mutableStateOf("") }
    var rest by remember { mutableStateOf("") }
    var rpe by remember { mutableStateOf("") }
    var expanded by remember { mutableStateOf(false) }

    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("Add Exercise") },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                ExposedDropdownMenuBox(expanded = expanded, onExpandedChange = { expanded = it }) {
                    OutlinedTextField(
                        value = selectedExercise?.name ?: "Select exercise",
                        onValueChange = {},
                        readOnly = true,
                        modifier = Modifier.menuAnchor(MenuAnchorType.PrimaryNotEditable),
                        label = { Text("Exercise") }
                    )
                    ExposedDropdownMenu(expanded = expanded, onDismissRequest = { expanded = false }) {
                        exercises.forEach { ex ->
                            DropdownMenuItem(
                                text = { Text(ex.name) },
                                onClick = {
                                    selectedExercise = ex
                                    expanded = false
                                }
                            )
                        }
                    }
                }
                OutlinedTextField(
                    value = numSets,
                    onValueChange = { numSets = it },
                    label = { Text("Number of sets") },
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number)
                )
                OutlinedTextField(
                    value = reps,
                    onValueChange = { reps = it },
                    label = { Text("Reps per set") },
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number)
                )
                OutlinedTextField(
                    value = weight,
                    onValueChange = { weight = it },
                    label = { Text("Weight ($weightUnit) (optional)") },
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal)
                )
                OutlinedTextField(
                    value = duration,
                    onValueChange = { duration = it },
                    label = { Text("Duration (secs)") },
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number)
                )
                OutlinedTextField(
                    value = rest,
                    onValueChange = { rest = it },
                    label = { Text("Rest (secs)") },
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number)
                )
                OutlinedTextField(
                    value = rpe,
                    onValueChange = { rpe = it },
                    label = { Text("Target RPE (optional)") },
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal)
                )
            }
        },
        confirmButton = {
            TextButton(
                onClick = {
                    selectedExercise?.let {
                        onConfirm(
                            it.id,
                            numSets.toIntOrNull() ?: 1,
                            reps.toIntOrNull() ?: 0,
                            weight.toDoubleOrNull() ?: 0.0,
                            rpe.toDoubleOrNull() ?: 0.0,
                            duration.toIntOrNull() ?: 0,
                            rest.toIntOrNull() ?: 0
                        )
                    }
                },
                enabled = selectedExercise != null
            ) { Text("Add") }
        },
        dismissButton = { TextButton(onClick = onDismiss) { Text("Cancel") } }
    )
}

@Composable
private fun EditTemplateSetDialog(
    exerciseName: String,
    set: OwtBridge.TemplateSet,
    onDismiss: () -> Unit,
    onConfirm: (Int, Double, Double, Int, Int) -> Unit
) {
    val context = LocalContext.current
    val weightUnit = remember { AppSettings.getWeightUnit(context) }
    var reps by remember { mutableStateOf(if (set.reps > 0) set.reps.toString() else "") }
    val displayWeight = if (set.weight > 0) AppSettings.toDisplayWeight(set.weight, context) else 0.0
    var weight by remember { mutableStateOf(if (set.weight > 0) "%.1f".format(displayWeight) else "") }
    var duration by remember { mutableStateOf(if (set.durationSecs > 0) set.durationSecs.toString() else "") }
    var rest by remember { mutableStateOf(if (set.restSecs > 0) set.restSecs.toString() else "") }
    var rpe by remember { mutableStateOf(if (set.rpe > 0) set.rpe.toString() else "") }

    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text(exerciseName) },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
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
                    onConfirm(
                        reps.toIntOrNull() ?: 0,
                        weight.toDoubleOrNull() ?: 0.0,
                        rpe.toDoubleOrNull() ?: 0.0,
                        duration.toIntOrNull() ?: 0,
                        rest.toIntOrNull() ?: 0
                    )
                }
            ) { Text("Save") }
        },
        dismissButton = { TextButton(onClick = onDismiss) { Text("Cancel") } }
    )
}
