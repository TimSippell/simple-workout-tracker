package com.timsippell.owt.ui.screens

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.Edit
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.navigation.NavController
import com.timsippell.owt.bridge.OwtBridge

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun TemplatesScreen(navController: NavController) {
    var templates by remember { mutableStateOf(OwtBridge.listTemplates()) }
    var showCreateDialog by remember { mutableStateOf(false) }
    var renamingTemplate by remember { mutableStateOf<OwtBridge.WorkoutTemplate?>(null) }
    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Workout Templates") },
                navigationIcon = {
                    IconButton(onClick = { navController.popBackStack() }) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back")
                    }
                }
            )
        },
        floatingActionButton = {
            FloatingActionButton(onClick = { showCreateDialog = true }) {
                Icon(Icons.Default.Add, contentDescription = "New template")
            }
        }
    ) { padding ->
        LazyColumn(
            modifier = Modifier.fillMaxSize().padding(padding),
            contentPadding = PaddingValues(16.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            items(templates, key = { it.id }) { template ->
                TemplateCard(
                    template = template,
                    onClick = {
                        navController.navigate("template_builder/${template.id}")
                    },
                    onRename = { renamingTemplate = template },
                    onDelete = {
                        OwtBridge.deleteTemplate(template.id)
                        templates = OwtBridge.listTemplates()
                    }
                )
            }
            if (templates.isEmpty()) {
                item {
                    Column(
                        modifier = Modifier.padding(32.dp).fillMaxWidth(),
                        horizontalAlignment = Alignment.CenterHorizontally,
                        verticalArrangement = Arrangement.spacedBy(16.dp)
                    ) {
                        Text(
                            "No templates yet. Tap + to create one, or load some recommended templates to get started.",
                            style = MaterialTheme.typography.bodyLarge
                        )
                        OutlinedButton(onClick = {
                            OwtBridge.seedDefaultTemplates()
                            templates = OwtBridge.listTemplates()
                        }) {
                            Text("Load recommended templates")
                        }
                    }
                }
            }
        }
    }

    renamingTemplate?.let { template ->
        RenameTemplateDialog(
            currentName = template.name,
            onDismiss = { renamingTemplate = null },
            onConfirm = { newName ->
                OwtBridge.updateTemplate(template.id, newName, template.notes)
                templates = OwtBridge.listTemplates()
                renamingTemplate = null
            }
        )
    }

    if (showCreateDialog) {
        CreateTemplateDialog(
            onDismiss = { showCreateDialog = false },
            onConfirm = { name ->
                val id = OwtBridge.createTemplate(name)
                showCreateDialog = false
                navController.navigate("template_builder/$id")
            }
        )
    }

}

internal fun seedDefaultTemplates() = OwtBridge.seedDefaultTemplates()

@Composable
private fun TemplateCard(
    template: OwtBridge.WorkoutTemplate,
    onClick: () -> Unit,
    onRename: () -> Unit,
    onDelete: () -> Unit
) {
    Card(modifier = Modifier.fillMaxWidth().clickable(onClick = onClick)) {
        Row(
            modifier = Modifier.padding(start = 16.dp, top = 4.dp, bottom = 4.dp, end = 4.dp).fillMaxWidth(),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Column(modifier = Modifier.weight(1f)) {
                Text(template.name, style = MaterialTheme.typography.titleMedium)
                Text(
                    "${template.setCount} sets",
                    style = MaterialTheme.typography.bodySmall
                )
            }
            IconButton(onClick = onRename) {
                Icon(Icons.Default.Edit, contentDescription = "Rename")
            }
            IconButton(onClick = onDelete) {
                Icon(Icons.Default.Delete, contentDescription = "Delete")
            }
        }
    }
}

@Composable
private fun CreateTemplateDialog(onDismiss: () -> Unit, onConfirm: (String) -> Unit) {
    var name by remember { mutableStateOf("") }

    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("New Template") },
        text = {
            OutlinedTextField(
                value = name,
                onValueChange = { name = it },
                label = { Text("Template name") },
                singleLine = true
            )
        },
        confirmButton = {
            TextButton(onClick = { onConfirm(name) }, enabled = name.isNotBlank()) {
                Text("Create")
            }
        },
        dismissButton = { TextButton(onClick = onDismiss) { Text("Cancel") } }
    )
}

@Composable
private fun RenameTemplateDialog(
    currentName: String,
    onDismiss: () -> Unit,
    onConfirm: (String) -> Unit
) {
    var name by remember { mutableStateOf(currentName) }

    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("Rename Template") },
        text = {
            OutlinedTextField(
                value = name,
                onValueChange = { name = it },
                label = { Text("Template name") },
                singleLine = true
            )
        },
        confirmButton = {
            TextButton(onClick = { onConfirm(name) }, enabled = name.isNotBlank()) {
                Text("Rename")
            }
        },
        dismissButton = { TextButton(onClick = onDismiss) { Text("Cancel") } }
    )
}
