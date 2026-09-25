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
    @State private var newName = ""
    @State private var newScript = ScriptTransformRunner.templateScript
    @State private var isPromptCopied = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Custom Transforms (JavaScript)").font(.headline)

            ForEach(store.transforms) { transform in
                HStack {
                    Text(transform.name).font(.callout)
                    Spacer()
                    Button(action: { remove(transform) }) {
                        Image(systemName: "trash").foregroundColor(.secondary)
                    }
                }
                Divider()
            }

            promptButton()

            Group {
                TextField("Name", text: $newName)
                Text("Script (define function transform(text))").font(.caption)
                TextEditor(text: $newScript)
                    .font(.system(.caption, design: .monospaced))
                    .frame(height: 110)
                    .border(Color.secondary.opacity(0.3))
                HStack {
                    Button("Reset to default") {
                        newScript = ScriptTransformRunner.templateScript
                    }
                    .disabled(newScript == ScriptTransformRunner.templateScript)
                    Button("Add", action: add)
                        .disabled(newName.isEmpty || newScript.isEmpty)
                }
            }
            .textFieldStyle(.roundedBorder)
        }
    }

    private func promptButton() -> some View {
        Button("Copy prompt for AI code generation") {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(AIPrompt.localized, forType: .string)
            PasteboardService.skipNextPasteboardChange = true
            isPromptCopied = true
        }
        .overlay(alignment: .trailing) {
            if isPromptCopied {
                Text("Copied!").font(.caption2).foregroundColor(.green).offset(x: 48)
            }
        }
    }

    private func remove(_ transform: CustomTransform) {
        guard let index = store.transforms.firstIndex(where: { $0.id == transform.id }) else { return }
        store.remove(at: IndexSet(integer: index))
    }

    private func add() {
        store.add(CustomTransform(name: newName, script: newScript))
        newName = ""
        newScript = ScriptTransformRunner.templateScript
    }
}
