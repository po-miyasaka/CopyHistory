import SwiftUI

struct TransformActionsBar: View {
    let item: CopiedItem
    let onTransform: (TransformAction) -> Void
    @ObservedObject var customStore = CustomTransformStore.shared
    @ObservedObject var usageTracker = TransformUsageTracker.shared
    @State private var showQRPopover = false
    @State private var qrImage: NSImage?
    @StateObject private var translationPreview = TranslationPreview()

    private var hasTextContent: Bool {
        item.rawString != nil && !(item.rawString?.isEmpty ?? true)
    }

    private var isWebLink: Bool {
        TextTransformer.webURL(from: item.rawString ?? "") != nil
    }

    private var sortedActions: [TransformAction] {
        let builtIn = TransformAction.allBuiltIn
        let custom = customStore.activeTransforms.map { TransformAction.custom($0) }
        // A link gets "Open in browser" first; using an action still moves it to the front.
        let leading: [TransformAction] = isWebLink ? [.openInBrowser] : []
        return usageTracker.sorted(leading + custom + builtIn)
    }

    var body: some View {
        if hasTextContent {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    ForEach(sortedActions) { action in
                        if action == .showQRCode {
                            qrCodeButton()
                        } else if action == .translate {
                            translateButton()
                        } else {
                            transformButton(action)
                        }
                    }
                }
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
        .help(Text(LocalizedStringKey(action.helpText)))
    }

    /// Hovering translates the text and shows the result as the tooltip.
    private func translateButton() -> some View {
        Button(action: {
            usageTracker.recordUsage(.translate)
            onTransform(.translate)
        }) {
            Label(TransformAction.translate.displayName, systemImage: TransformAction.translate.iconName)
                .font(.caption2)
                .lineLimit(1)
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
        .onHover { hovering in
            if hovering { translationPreview.load(item.rawString ?? "") }
        }
        .help(translationPreview.tooltip)
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
        .help(Text(LocalizedStringKey(TransformAction.showQRCode.helpText)))
    }
}
