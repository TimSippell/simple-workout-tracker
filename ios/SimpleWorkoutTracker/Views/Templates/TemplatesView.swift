import SwiftUI

struct TemplatesView: View {
    var onDismiss: () -> Void = {}
    var onEditTemplate: (Int64) -> Void = { _ in }

    @State private var templates: [WorkoutTemplate] = []
    @State private var showCreateAlert = false
    @State private var newTemplateName = ""

    var body: some View {
        List {
            ForEach(templates) { template in
                Button {
                    onEditTemplate(template.id)
                } label: {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(template.name).font(.headline)
                        Text("\(template.setCount) sets")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .foregroundStyle(.primary)
            }
            .onDelete { indexSet in
                for index in indexSet {
                    SwtBridge.shared.deleteTemplate(id: templates[index].id)
                }
                reload()
            }

            if templates.isEmpty {
                VStack(spacing: 16) {
                    Text("No templates yet. Tap + to create one, or load some recommended templates.")
                        .foregroundStyle(.secondary)
                    Button("Load recommended templates") {
                        SwtBridge.shared.seedDefaultTemplates()
                        reload()
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
            }
        }
        .navigationTitle("Workout Templates")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Done") { onDismiss() }
            }
            ToolbarItem(placement: .primaryAction) {
                Button { showCreateAlert = true } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .onAppear { reload() }
        .alert("New Template", isPresented: $showCreateAlert) {
            TextField("Template name", text: $newTemplateName)
            Button("Create") {
                let id = SwtBridge.shared.createTemplate(name: newTemplateName)
                newTemplateName = ""
                reload()
                onEditTemplate(id)
            }
            .disabled(newTemplateName.isEmpty)
            Button("Cancel", role: .cancel) { newTemplateName = "" }
        }
    }

    private func reload() {
        templates = SwtBridge.shared.listTemplates()
    }
}
