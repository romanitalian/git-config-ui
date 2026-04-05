import SwiftUI

struct AliasEditor: View {
    let existingKey: String?   // nil = new alias
    let onSave: (Alias) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var key: String
    @State private var value: String
    @FocusState private var focusedField: Field?

    private enum Field { case key, value }

    init(alias: Alias?, onSave: @escaping (Alias) -> Void) {
        self.existingKey = alias?.key
        self.onSave = onSave
        _key   = State(initialValue: alias?.key   ?? "")
        _value = State(initialValue: alias?.value ?? "")
    }

    private var isValid: Bool {
        !key.trimmingCharacters(in: .whitespaces).isEmpty &&
        !value.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            Text(existingKey == nil ? "New Alias" : "Edit Alias")
                .font(.headline)
                .padding(.top, 16)
                .padding(.bottom, 12)

            Grid(alignment: .leadingFirstTextBaseline, horizontalSpacing: 8, verticalSpacing: 10) {
                GridRow {
                    Text("Key:")
                        .frame(width: 50, alignment: .trailing)
                    TextField("e.g. co", text: $key)
                        .textFieldStyle(.roundedBorder)
                        .focused($focusedField, equals: .key)
                        .onChange(of: key) { newValue in
                            // strip spaces and dots — not valid in alias keys
                            let filtered = newValue.filter { !$0.isWhitespace && $0 != "." }
                            if filtered != newValue { key = filtered }
                        }
                }
                GridRow {
                    Text("Value:")
                        .frame(width: 50, alignment: .trailing)
                        .padding(.top, 4)
                    TextEditor(text: $value)
                        .font(.system(.body, design: .monospaced))
                        .frame(minHeight: 120)
                        .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color(NSColor.separatorColor)))
                        .focused($focusedField, equals: .value)
                }
            }
            .padding(.horizontal, 20)

            Divider().padding(.top, 12)

            HStack {
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button("Save") {
                    onSave(Alias(key: key.trimmingCharacters(in: .whitespaces),
                                 value: value.trimmingCharacters(in: .whitespaces)))
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(!isValid)
            }
            .padding(16)
        }
        .frame(width: 480)
        .onAppear { focusedField = existingKey == nil ? .key : .value }
    }
}
