package com.timsippell.owt.ui.components

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import com.timsippell.owt.bridge.OwtBridge
import com.timsippell.owt.ui.screens.AppSettings

@Composable
fun EditSetDialog(
    set: OwtBridge.WorkoutSet,
    exercises: List<OwtBridge.Exercise>,
    onDismiss: () -> Unit,
    onConfirm: (Int, Double, Double, Int, Int) -> Unit
) {
    val context = LocalContext.current
    val weightUnit = remember { AppSettings.getWeightUnit(context) }
    val exercise = exercises.find { it.id == set.exerciseId }
    val exerciseName = exercise?.name ?: "Unknown"
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
