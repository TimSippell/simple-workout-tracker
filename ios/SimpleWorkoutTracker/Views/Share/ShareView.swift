import SwiftUI

struct ShareView: View {
    @StateObject private var session = MultipeerShareSession()

    var body: some View {
        VStack {
            switch session.state {
            case .idle:
                idleContent
            case .selectingTemplates:
                SelectTemplatesContent(
                    onConfirm: { ids in session.startSending(selectedTemplateIds: ids) },
                    onCancel: { session.cancel() }
                )
            case .browsing:
                searchingContent(message: "Searching for nearby devices...")
            case .advertising:
                searchingContent(message: "Waiting for sender...")
            case .connecting(let peerName):
                connectingContent(peerName: peerName)
            case .transferring(let progress):
                transferringContent(progress: progress)
            case .reviewingImport(let json):
                reviewingImportContent(json: json)
            case .complete(let message):
                completeContent(message: message)
            case .error(let message):
                errorContent(message: message)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle("Share Workouts")
    }

    // MARK: - Idle

    private var idleContent: some View {
        VStack(spacing: 24) {
            Image(systemName: "antenna.radiowaves.left.and.right")
                .font(.system(size: 72))
                .foregroundStyle(.tint)

            Text("Share workout data with another device")
                .multilineTextAlignment(.center)

            Button("Send My Data") { session.promptSend() }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)

            Button("Receive Data") { session.startReceiving() }
                .buttonStyle(.bordered)
                .frame(maxWidth: .infinity)

            Text("Both devices need the app open.\nDevices must be nearby on the same network or Bluetooth.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Searching/Advertising

    private func searchingContent(message: String) -> some View {
        VStack(spacing: 24) {
            Image(systemName: "wifi")
                .font(.system(size: 72))
                .foregroundStyle(.tint)
            Text(message)
            ProgressView()
            Button("Cancel") { session.cancel() }
                .buttonStyle(.bordered)
        }
    }

    // MARK: - Connecting

    private func connectingContent(peerName: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 48))
                .foregroundStyle(.tint)
            Text("Connecting to \(peerName)...")
            ProgressView()
        }
    }

    // MARK: - Transferring

    private func transferringContent(progress: Float) -> some View {
        VStack(spacing: 16) {
            Text("Transferring...")
            ProgressView(value: progress)
            Text("\(Int(progress * 100))%")
        }
    }

    // MARK: - Reviewing Import

    private func reviewingImportContent(json: String) -> some View {
        VStack(spacing: 16) {
            Text("Data Received")
                .font(.title2.bold())

            if let summary = session.importSummary {
                GroupBox {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(summary.newExercises) new exercises")
                        if summary.existingExercises > 0 {
                            Text("\(summary.existingExercises) already exist")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Text("\(summary.workouts) workouts with \(summary.workoutSets) sets")
                        Text("\(summary.templates) templates with \(summary.templateSets) sets")
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            Text("Existing data will not be modified.")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                Button("Cancel") { session.cancel() }
                    .buttonStyle(.bordered)
                Button("Import") { session.confirmImport(json) }
                    .buttonStyle(.borderedProminent)
            }
        }
    }

    // MARK: - Complete

    private func completeContent(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 72))
                .foregroundStyle(.tint)
            Text(message)
                .multilineTextAlignment(.center)
            Button("Done") { session.reset() }
                .buttonStyle(.borderedProminent)
        }
    }

    // MARK: - Error

    private func errorContent(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 72))
                .foregroundStyle(.red)
            Text(message)
                .multilineTextAlignment(.center)
            HStack(spacing: 12) {
                Button("Back") { session.cancel() }
                    .buttonStyle(.bordered)
                Button("Retry") { session.reset() }
                    .buttonStyle(.borderedProminent)
            }
        }
    }
}

// MARK: - Template Selection

private struct SelectTemplatesContent: View {
    let onConfirm: (Set<Int64>) -> Void
    let onCancel: () -> Void

    @State private var templates: [WorkoutTemplate] = []
    @State private var selected: Set<Int64> = []

    var body: some View {
        VStack(spacing: 12) {
            Text("Select Templates to Send")
                .font(.title3.bold())

            if templates.isEmpty {
                Text("No templates to send")
                    .foregroundStyle(.secondary)
            } else {
                HStack {
                    Button("Select All") {
                        selected = Set(templates.map(\.id))
                    }
                    Button("Select None") {
                        selected.removeAll()
                    }
                }
                .buttonStyle(.borderless)

                List(templates, id: \.id) { template in
                    HStack {
                        Image(systemName: selected.contains(template.id) ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(selected.contains(template.id) ? .blue : .secondary)
                        VStack(alignment: .leading) {
                            Text(template.name)
                            Text("\(template.setCount) sets")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if selected.contains(template.id) {
                            selected.remove(template.id)
                        } else {
                            selected.insert(template.id)
                        }
                    }
                }
                .listStyle(.plain)
            }

            HStack(spacing: 12) {
                Button("Cancel", action: onCancel)
                    .buttonStyle(.bordered)
                Button("Send \(selected.count) template\(selected.count == 1 ? "" : "s")") {
                    onConfirm(selected)
                }
                .buttonStyle(.borderedProminent)
                .disabled(selected.isEmpty)
            }
        }
        .onAppear {
            templates = SwtBridge.shared.listTemplates()
            selected = Set(templates.map(\.id))
        }
    }
}
