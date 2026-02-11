import SwiftUI

struct TransformActionsBar: View {
    let item: CopiedItem
    let onTransform: (TransformAction) -> Void
    @ObservedObject var customStore = CustomTransformStore.shared
    @ObservedObject var usageTracker = TransformUsageTracker.shared
    @State private var showQRPopover = false
    @State private var qrImage: NSImage?

    private var hasTextContent: Bool {
        item.rawString != nil && !(item.rawString?.isEmpty ?? true)
    }

    private var sortedActions: [TransformAction] {
        let builtIn = TransformAction.allBuiltIn
        let custom = customStore.transforms.map { TransformAction.custom($0) }
        return usageTracker.sorted(builtIn + custom)
    }

    var body: some View {
        if hasTextContent {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    ForEach(sortedActions) { action in
                        if action == .showQRCode {
                            qrCodeButton()
                        } else {
                            transformButton(action)
                        }
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
            }
            .popover(isPresented: $showQRPopover) {
                if let qrImage {
                    Image(nsImage: qrImage)
                        .resizable()
                        .interpolation(.none)
                        .scaledToFit()
                        .frame(width: 200, height: 200)
                        .padding()
                }
            }
        }
    }

    private func transformButton(_ action: TransformAction) -> some View {
        Button(action: {
            usageTracker.recordUsage(action)
            onTransform(action)
        }) {
            Label(action.displayName, systemImage: action.iconName)
                .font(.caption2)
                .lineLimit(1)
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
        .help(action.helpText)
    }

    private func qrCodeButton() -> some View {
        Button(action: {
            usageTracker.recordUsage(.showQRCode)
            guard let rawString = item.rawString else { return }
            qrImage = TextTransformer.generateQRCode(from: rawString)
            showQRPopover = qrImage != nil
        }) {
            Label(TransformAction.showQRCode.displayName, systemImage: TransformAction.showQRCode.iconName)
                .font(.caption2)
                .lineLimit(1)
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
        .help(TransformAction.showQRCode.helpText)
    }
}
