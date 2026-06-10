import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    var onNavigateToSetup: () -> Void = {}

    @State private var weightUnit = "kg"
    @State private var showResetAlert = false
    @State private var exportMessage: String?
    @State private var importMessage: String?
    @State private var showExporter = false
    @State private var showImporter = false
    @State private var pendingImportJson: String?
    @State private var importSummary: ImportSummary?

    var body: some View {
        Form {
            Section("Weight Unit") {
                Picker("Unit", selection: $weightUnit) {
                    Text("kg").tag("kg")
                    Text("lbs").tag("lbs")
                }
                .pickerStyle(.segmented)
                .onChange(of: weightUnit) { newValue in
                    SwtBridge.shared.setWeightUnit(newValue)
                }
            }

            Section("Setup") {
                Button("Set Up One Rep Max") { onNavigateToSetup() }
            }

            Section("Data") {
                Button("Export Data") { showExporter = true }
                if let msg = exportMessage {
                    Text(msg).font(.caption).foregroundStyle(.secondary)
                }
                Button("Import Data") { showImporter = true }
                if let msg = importMessage {
                    Text(msg).font(.caption).foregroundStyle(.secondary)
                }
            }

            Section {
                Link("Privacy Policy", destination: URL(string: "https://github.com/TimSippell/offline-workout-tracker/blob/main/PRIVACY_POLICY.md")!)
            }

            Section {
                Button("Reset All Data", role: .destructive) { showResetAlert = true }
            } header: {
                Text("Danger Zone")
            }
        }
        .navigationTitle("Settings")
        .onAppear { weightUnit = SwtBridge.shared.getWeightUnit() }
        .alert("Reset All Data", isPresented: $showResetAlert) {
            Button("Delete Everything", role: .destructive) {
                SwtBridge.shared.close()
                let supportDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
                let dbPath = supportDir.appendingPathComponent("swt.db")
                try? FileManager.default.removeItem(at: dbPath)
                SwtBridge.shared.initialize()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete all exercises, workouts, templates, and history. This cannot be undone.")
        }
        .alert("Import Data", isPresented: Binding(
            get: { importSummary != nil },
            set: { if !$0 { importSummary = nil; pendingImportJson = nil } }
        )) {
            Button("Import") {
                if let json = pendingImportJson {
                    importMessage = SwtBridge.shared.importFromJson(json: json)
                }
                importSummary = nil
                pendingImportJson = nil
            }
            Button("Cancel", role: .cancel) {
                importSummary = nil
                pendingImportJson = nil
            }
        } message: {
            if let s = importSummary {
                Text("""
                This will import:
                \u{2022} \(s.newExercises) new exercises\(s.existingExercises > 0 ? " (\(s.existingExercises) already exist)" : "")
                \u{2022} \(s.workouts) workouts with \(s.workoutSets) sets
                \u{2022} \(s.templates) templates with \(s.templateSets) sets

                Existing data will not be modified.
                """)
            }
        }
        .fileExporter(
            isPresented: $showExporter,
            document: JsonDocument(json: SwtBridge.shared.exportToJson()),
            contentType: .json,
            defaultFilename: "swt-export.json"
        ) { result in
            switch result {
            case .success: exportMessage = "Data exported successfully"
            case .failure(let error): exportMessage = "Export failed: \(error.localizedDescription)"
            }
        }
        .fileImporter(
            isPresented: $showImporter,
            allowedContentTypes: [.json]
        ) { result in
            switch result {
            case .success(let url):
                guard url.startAccessingSecurityScopedResource() else { return }
                defer { url.stopAccessingSecurityScopedResource() }
                do {
                    let json = try String(contentsOf: url, encoding: .utf8)
                    if let summary = SwtBridge.shared.previewImport(json: json) {
                        pendingImportJson = json
                        importSummary = summary
                    } else {
                        importMessage = "Could not parse import file"
                    }
                } catch {
                    importMessage = "Import failed: \(error.localizedDescription)"
                }
            case .failure(let error):
                importMessage = "Import failed: \(error.localizedDescription)"
            }
        }
    }
}

struct JsonDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    var json: String

    init(json: String) { self.json = json }
    init(configuration: ReadConfiguration) throws {
        json = String(data: configuration.file.regularFileContents ?? Data(), encoding: .utf8) ?? "{}"
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: Data(json.utf8))
    }
}
