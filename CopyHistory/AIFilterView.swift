import SwiftUI

struct AIFilterButton: View {
    @ObservedObject var controller: AIFilterController
    @Binding var showsUnjudged: Bool
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
                    Text(label).font(.caption).lineLimit(1)
                }
                .foregroundColor(controller.isActive ? Color.mainAccent : Color.primary)
            })
            .help("Filter with on-device AI")
            .popover(isPresented: $isPresented) {
                AIFilterPopover(
                    controller: controller,
                    showsUnjudged: $showsUnjudged,
                    matchCount: matchCount,
                    onApply: onApply,
                    onClear: {
                        isPresented = false
                        onClear()
                    },
                    onExport: onExport
                )
            }
        }
    }

    private var label: String {
        let title = String(localized: "AI Filter")
        guard controller.isActive else { return title }
        let query = String(controller.query.prefix(12))
        guard let progress = controller.progress else { return "\(title): \(query)" }
        return "\(title): \(query) \(progress.done)/\(progress.total)"
    }
}

private struct AIFilterPopover: View {
    @ObservedObject var controller: AIFilterController
    @Binding var showsUnjudged: Bool
    let matchCount: Int
    let onApply: (String) -> Void
    let onClear: () -> Void
    let onExport: () -> Void

    @State private var draft: String

    init(controller: AIFilterController, showsUnjudged: Binding<Bool>, matchCount: Int,
         onApply: @escaping (String) -> Void, onClear: @escaping () -> Void, onExport: @escaping () -> Void) {
        self.controller = controller
        _showsUnjudged = showsUnjudged
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
                    ProgressView(value: min(max(Double(progress.done) / Double(max(progress.total, 1)),
                                            Double(matchCount) / Double(max(controller.limit, 1))), 1))
                    Text("Checked \(progress.done)/\(progress.total) · Found \(matchCount)/\(controller.limit)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else if controller.isActive {
                Text(statusText)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Toggle("Show items that couldn't be judged", isOn: $showsUnjudged)
                .font(.caption)

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

    private var statusText: LocalizedStringKey {
        if controller.isStopped { return "Stopped · \(matchCount)" }
        return controller.reachedLimit ? "Reached the limit · \(matchCount)" : "Done · \(matchCount)"
    }

    private func apply() {
        guard !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        onApply(draft)
    }
}
