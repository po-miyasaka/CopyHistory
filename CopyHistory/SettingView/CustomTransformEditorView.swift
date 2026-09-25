import SwiftUI
import AppKit

private enum AIPrompt {
    static let english = """
    Write a JavaScript function for a text-transform tool.

    Requirements:
    - Define exactly one function with the signature: function transform(text)
    - `text` is a string (the copied text). Return the transformed string.
    - Plain JavaScript (ES2015+) running in JavaScriptCore. No DOM, no Node.js APIs (no require/import), no network or file access, no async/await/Promises.
    - It must finish quickly (under 2 seconds).
    - Output only the code, with no explanation.

    What I want the function to do:
    (describe here)
    """

    static var localized: String {
        Bundle.main.preferredLocalizations.first == "ja" ? japanese : english
    }

    static let japanese = """
    テキスト変換ツール用の JavaScript 関数を書いてください。

    要件:
    - シグネチャは function transform(text) の関数を1つだけ定義すること
    - text は文字列（コピーしたテキスト）。変換後の文字列を return すること
    - JavaScriptCore で動く素の JavaScript (ES2015+)。DOM や Node.js の API (require/import) は使えず、ネットワークやファイルアクセス、async/await/Promise も使わないこと
    - 2秒以内に終わること
    - 説明は不要で、コードだけを出力すること

    やりたい変換:
    （ここに書く）
    """
}

struct CustomTransformEditorView: View {
    @ObservedObject var store = CustomTransformStore.shared
    @State private var isPromptCopied = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Custom Transform Action").font(.headline)

            TextEditor(text: $store.script)
                .font(.system(.caption, design: .monospaced))
                .frame(height: 110)
                .border(Color.secondary.opacity(0.3))

            HStack {
                Button("Reset to default", action: store.resetToDefault)
                    .disabled(store.script == ScriptTransformRunner.templateScript)
                Button("Copy prompt for AI code generation", action: copyPrompt)
                if isPromptCopied {
                    Text("Copied!").font(.caption).foregroundColor(.green)
                }
            }
        }
    }

    private func copyPrompt() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(AIPrompt.localized, forType: .string)
        PasteboardService.skipNextPasteboardChange = true
        isPromptCopied = true
    }
}
