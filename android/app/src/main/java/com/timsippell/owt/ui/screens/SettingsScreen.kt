package com.timsippell.owt.ui.screens

import android.content.Context
import android.content.Intent
import android.net.Uri
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import com.timsippell.owt.bridge.OwtBridge

object AppSettings {
    private const val KG_TO_LBS = 2.20462

    fun getWeightUnit(context: Context): String = OwtBridge.getWeightUnit()
    fun setWeightUnit(context: Context, unit: String) = OwtBridge.setWeightUnit(unit)

    fun toDisplayWeight(storedKg: Double, unit: String): Double =
        if (unit == "lbs") storedKg * KG_TO_LBS else storedKg

    fun toDisplayWeight(storedKg: Double, context: Context): Double =
        toDisplayWeight(storedKg, getWeightUnit(context))

    fun toStorageWeight(displayValue: Double, unit: String): Double =
        if (unit == "lbs") displayValue / KG_TO_LBS else displayValue

    fun toStorageWeight(displayValue: Double, context: Context): Double =
        toStorageWeight(displayValue, getWeightUnit(context))

    fun isSetupComplete(context: Context): Boolean = OwtBridge.isSetupComplete()
    fun setSetupComplete(context: Context, complete: Boolean) = OwtBridge.setSetupComplete(complete)

    fun getOneRepMax(context: Context, exerciseId: Long): Double = OwtBridge.getOneRepMax(exerciseId)
    fun setOneRepMax(context: Context, exerciseId: Long, weight: Double) =
        OwtBridge.setOneRepMax(exerciseId, weight)
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SettingsScreen(onNavigateToSetup: () -> Unit = {}, onNavigateToShare: () -> Unit = {}) {
    val context = LocalContext.current
    var weightUnit by remember { mutableStateOf(AppSettings.getWeightUnit(context)) }
    var showResetDialog by remember { mutableStateOf(false) }
    var exportMessage by remember { mutableStateOf<String?>(null) }
    var importMessage by remember { mutableStateOf<String?>(null) }
    var pendingImportJson by remember { mutableStateOf<String?>(null) }
    var importSummary by remember { mutableStateOf<OwtBridge.ImportSummary?>(null) }

    val exportLauncher = rememberLauncherForActivityResult(
        ActivityResultContracts.CreateDocument("application/json")
    ) { uri ->
        if (uri != null) {
            try {
                val json = exportDataToJson()
                context.contentResolver.openOutputStream(uri)?.use { stream ->
                    stream.write(json.toByteArray())
                }
                exportMessage = "Data exported successfully"
            } catch (e: Exception) {
                exportMessage = "Export failed: ${e.message}"
            }
        }
    }

    val importLauncher = rememberLauncherForActivityResult(
        ActivityResultContracts.OpenDocument()
    ) { uri ->
        if (uri != null) {
            try {
                val maxImportSize = 50L * 1024 * 1024
                val json = context.contentResolver.openInputStream(uri)?.use { stream ->
                    val reader = stream.bufferedReader()
                    val buf = CharArray(8192)
                    val sb = StringBuilder()
                    var total = 0L
                    var n: Int
                    while (reader.read(buf).also { n = it } != -1) {
                        total += n
                        if (total > maxImportSize) throw Exception("File too large (max 50 MB)")
                        sb.append(buf, 0, n)
                    }
                    sb.toString()
                } ?: throw Exception("Could not read file")
                val summary = previewImport(json)
                pendingImportJson = json
                importSummary = summary
            } catch (e: Exception) {
                importMessage = "Import failed: ${e.message}"
            }
        }
    }

    Scaffold(
        topBar = { TopAppBar(title = { Text("Settings") }) }
    ) { padding ->
        Column(
            modifier = Modifier.fillMaxSize().padding(padding).padding(16.dp).verticalScroll(rememberScrollState()),
            verticalArrangement = Arrangement.spacedBy(24.dp)
        ) {
            Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                Text("Weight Unit", style = MaterialTheme.typography.titleMedium)
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    FilterChip(
                        selected = weightUnit == "kg",
                        onClick = {
                            weightUnit = "kg"
                            AppSettings.setWeightUnit(context, "kg")
                        },
                        label = { Text("kg") }
                    )
                    FilterChip(
                        selected = weightUnit == "lbs",
                        onClick = {
                            weightUnit = "lbs"
                            AppSettings.setWeightUnit(context, "lbs")
                        },
                        label = { Text("lbs") }
                    )
                }
            }

            HorizontalDivider()

            Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                Text("Setup", style = MaterialTheme.typography.titleMedium)
                OutlinedButton(
                    onClick = onNavigateToSetup,
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Text("Set Up One Rep Max")
                }
            }

            HorizontalDivider()

            Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                Text("Data", style = MaterialTheme.typography.titleMedium)
                OutlinedButton(
                    onClick = { exportLauncher.launch("owt-export.json") },
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Text("Export Data")
                }
                exportMessage?.let {
                    Text(it, style = MaterialTheme.typography.bodySmall)
                }
                OutlinedButton(
                    onClick = { importLauncher.launch(arrayOf("application/json")) },
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Text("Import Data")
                }
                importMessage?.let {
                    Text(it, style = MaterialTheme.typography.bodySmall)
                }
                OutlinedButton(
                    onClick = onNavigateToShare,
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Text("Share via NFC")
                }
            }

            HorizontalDivider()

            Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                Text("About", style = MaterialTheme.typography.titleMedium)
                OutlinedButton(
                    onClick = {
                        val intent = Intent(Intent.ACTION_VIEW,
                            Uri.parse("https://github.com/TimSippell/offline-workout-tracker/blob/main/PRIVACY_POLICY.md"))
                        context.startActivity(intent)
                    },
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Text("Privacy Policy")
                }
            }

            HorizontalDivider()

            Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                Text("Danger Zone", style = MaterialTheme.typography.titleMedium,
                    color = MaterialTheme.colorScheme.error)
                OutlinedButton(
                    onClick = { showResetDialog = true },
                    modifier = Modifier.fillMaxWidth(),
                    colors = ButtonDefaults.outlinedButtonColors(
                        contentColor = MaterialTheme.colorScheme.error
                    )
                ) {
                    Text("Reset All Data")
                }
            }
        }
    }

    if (showResetDialog) {
        AlertDialog(
            onDismissRequest = { showResetDialog = false },
            title = { Text("Reset All Data") },
            text = { Text("This will permanently delete all exercises, workouts, templates, and history. This cannot be undone.") },
            confirmButton = {
                TextButton(
                    onClick = {
                        val dbFile = context.getDatabasePath("owt.db")
                        OwtBridge.close()
                        dbFile.delete()
                        OwtBridge.init(context)
                        showResetDialog = false
                    },
                    colors = ButtonDefaults.textButtonColors(
                        contentColor = MaterialTheme.colorScheme.error
                    )
                ) { Text("Delete Everything") }
            },
            dismissButton = {
                TextButton(onClick = { showResetDialog = false }) { Text("Cancel") }
            }
        )
    }

    importSummary?.let { summary ->
        AlertDialog(
            onDismissRequest = {
                importSummary = null
                pendingImportJson = null
            },
            title = { Text("Import Data") },
            text = {
                Text(buildString {
                    append("This will import:\n")
                    append("• ${summary.newExercises} new exercises")
                    if (summary.existingExercises > 0) append(" (${summary.existingExercises} already exist)")
                    append("\n• ${summary.workouts} workouts with ${summary.workoutSets} sets")
                    append("\n• ${summary.templates} templates with ${summary.templateSets} sets")
                    append("\n\nExisting data will not be modified.")
                })
            },
            confirmButton = {
                TextButton(onClick = {
                    try {
                        val result = importDataFromJson(pendingImportJson!!)
                        importMessage = result
                    } catch (e: Exception) {
                        importMessage = "Import failed: ${e.message}"
                    }
                    importSummary = null
                    pendingImportJson = null
                }) { Text("Import") }
            },
            dismissButton = {
                TextButton(onClick = {
                    importSummary = null
                    pendingImportJson = null
                }) { Text("Cancel") }
            }
        )
    }
}

private fun previewImport(json: String): OwtBridge.ImportSummary? = OwtBridge.previewImport(json)
private fun importDataFromJson(json: String): String = OwtBridge.importFromJson(json)
private fun exportDataToJson(): String = OwtBridge.exportToJson()
