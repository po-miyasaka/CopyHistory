import SwiftUI

struct CustomTransformEditorView: View {
    @ObservedObject var store = CustomTransformStore.shared
    @State private var newName = ""
    @State private var newPattern = ""
    @State private var newReplacement = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Custom Transforms (Regex)").font(.headline)

            ForEach(store.transforms) { transform in
                HStack {
                    VStack(alignment: .leading) {
                        Text(transform.name).font(.callout)
                        Text("pattern: \(transform.pattern)")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text("replacement: \(transform.replacement)")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    Spacer()
                    Button(action: {
                        if let index = store.transforms.firstIndex(where: { $0.id == transform.id }) {
                            store.remove(at: IndexSet(integer: index))
                        }
                    }) {
                        Image(systemName: "trash").foregroundColor(.secondary)
                    }
                }
                Divider()
            }

            Group {
                TextField("Name", text: $newName)
                TextField("Regex Pattern", text: $newPattern)
                TextField("Replacement ($1, $2...)", text: $newReplacement)
                Button("Add") {
                    store.add(CustomTransform(name: newName, pattern: newPattern, replacement: newReplacement))
                    newName = ""
                    newPattern = ""
                    newReplacement = ""
                }
                .disabled(newName.isEmpty || newPattern.isEmpty)
            }
            .textFieldStyle(.roundedBorder)
        }
    }
}
