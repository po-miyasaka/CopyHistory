import SwiftUI

struct AIFilterButton: View {
    @ObservedObject var controller: AIFilterController
    let matchCount: Int
    let onApply: (String) -> Void
    let onClear: () -> Void
    let onExport: () -> Void

    @State private var isPresented = false

    var body: some View {
        HStack(spacing: 4) {
            Button(action: { isPresented = true }, label: {
                HStack(spacing: 4) {
                    Image(systemName: "sparkles")
                    if controller.isActive {
                        Text(label).font(.caption).lineLimit(1)
                    }
                }
                .foregroundColor(controller.isActive ? Color.mainAccent : Color.primary)
            })
            .help("Filter with on-device AI")
            .popover(isPresented: $isPresented) {
                AIFilterPopover(
                    controller: controller,
                    matchCount: matchCount,
                    onApply: { query in
                        isPresented = false
                        onApply(query)
                    },
                    onClear: {
                        isPresented = false
                        onClear()
                    },
                    onExport: onExport
                )
            }

            if controller.progress != nil {
                Button(action: controller.stop) {
                    Image(systemName: "stop.circle.fill").foregroundColor(.red)
                }
                .help("Stop")
            }
        }
    }

    private var label: String {
        let query = String(controller.query.prefix(16))
        guard let progress = controller.progress else { return query }
        return "\(query) \(progress.done)/\(progress.total)"
    }
}

private struct AIFilterPopover: View {
    @ObservedObject var controller: AIFilterController
    let matchCount: Int
    let onApply: (String) -> Void
    let onClear: () -> Void
    let onExport: () -> Void

    @State private var draft: String

    init(controller: AIFilterController, matchCount: Int,
         onApply: @escaping (String) -> Void, onClear: @escaping () -> Void, onExport: @escaping () -> Void) {
        self.controller = controller
        self.matchCount = matchCount
        self.onApply = onApply
        self.onClear = onClear
        self.onExport = onExport
        _draft = State(initialValue: controller.query)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            TextField("Describe what to show (e.g. food)", text: $draft)
                .textFieldStyle(.roundedBorder)
                .onSubmit(apply)

            if let progress = controller.progress {
                VStack(alignment: .leading, spacing: 4) {
                    ProgressView(value: Double(progress.done), total: Double(max(progress.total, 1)))
                    Text("\(progress.done)/\(progress.total) · \(matchCount)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else if controller.isActive {
                Text(controller.isStopped ? "Stopped · \(matchCount)" : "Done · \(matchCount)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if controller.failedCount > 0 {
                Text("Couldn't judge \(controller.failedCount) items")
                    .font(.caption)
                    .foregroundColor(.red)
            }

            HStack {
                if controller.isActive {
                    Button("Clear", action: onClear)
                    Button("Export as CSV…", action: onExport)
                }
                Spacer()
                if controller.progress != nil {
                    Button("Stop", action: controller.stop)
                }
                Button("Apply", action: apply)
                    .keyboardShortcut(.defaultAction)
                    .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(16)
        .frame(width: 340)
    }

    private func apply() {
        guard !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        onApply(draft)
    }
}
