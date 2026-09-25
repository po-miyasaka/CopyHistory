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
    @State private var testInput = ""
    @State private var testOutput: String?
    @State private var testFailed = false
    @State private var copiedLabel: String?

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

            Text("Ask an AI to write the script: copy a prompt, add what you want, and paste the code below.")
                .font(.caption)
                .foregroundColor(.secondary)
            HStack {
                promptButton("Copy AI prompt (English)", text: AIPrompt.english)
                promptButton("Copy AI prompt (Japanese)", text: AIPrompt.japanese)
            }

            Group {
                TextField("Name", text: $newName)
                Text("Script (define function transform(text))").font(.caption)
                TextEditor(text: $newScript)
                    .font(.system(.caption, design: .monospaced))
                    .frame(height: 110)
                    .border(Color.secondary.opacity(0.3))
                TextField("Test input", text: $testInput)
                HStack {
                    Button("Test", action: runTest)
                    Button("Reset to default") {
                        newScript = ScriptTransformRunner.templateScript
                        testOutput = nil
                    }
                    .disabled(newScript == ScriptTransformRunner.templateScript)
                    Button("Add", action: add)
                        .disabled(newName.isEmpty || newScript.isEmpty)
                }
                if let testOutput {
                    Text("Result:").font(.caption)
                    Text(testOutput)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(testFailed ? .red : .primary)
                        .textSelection(.enabled)
                }
            }
            .textFieldStyle(.roundedBorder)
        }
    }

    private func promptButton(_ title: LocalizedStringKey, text: String) -> some View {
        Button(title) {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(text, forType: .string)
            PasteboardService.skipNextPasteboardChange = true
            copiedLabel = text
        }
        .overlay(alignment: .trailing) {
            if copiedLabel == text {
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
        testOutput = nil
    }

    private func runTest() {
        switch ScriptTransformRunner.run(script: newScript, input: testInput) {
        case .success(let output):
            testFailed = false
            testOutput = output
        case .failure(let error):
            testFailed = true
            testOutput = error.localizedDescription
        }
    }
}
