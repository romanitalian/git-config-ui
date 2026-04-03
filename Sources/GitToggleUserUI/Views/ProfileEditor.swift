import SwiftUI

struct ProfileEditor: View {
    let profile: Profile?
    let onSave: (Profile) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var label: String
    @State private var name: String
    @State private var email: String
    @FocusState private var focusedField: Field?

    private let profileId: String

    private enum Field: Hashable {
        case label, name, email
    }

    init(profile: Profile?, onSave: @escaping (Profile) -> Void) {
        self.profile = profile
        self.onSave = onSave
        self.profileId = profile?.id ?? UUID().uuidString
        _label = State(initialValue: profile?.label ?? "")
        _name = State(initialValue: profile?.name ?? "")
        _email = State(initialValue: profile?.email ?? "")
    }

    private var isValid: Bool {
        !label.trimmingCharacters(in: .whitespaces).isEmpty &&
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        !email.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            Text(profile == nil ? "New Profile" : "Edit Profile")
                .font(.headline)
                .padding(.top, 16)
                .padding(.bottom, 12)

            Grid(alignment: .leadingFirstTextBaseline, horizontalSpacing: 8, verticalSpacing: 10) {
                GridRow {
                    Text("Label:")
                        .frame(width: 50, alignment: .trailing)
                    TextField("", text: $label)
                        .textFieldStyle(.roundedBorder)
                        .focused($focusedField, equals: .label)
                }
                GridRow {
                    Text("Name:")
                        .frame(width: 50, alignment: .trailing)
                    TextField("", text: $name)
                        .textFieldStyle(.roundedBorder)
                        .focused($focusedField, equals: .name)
                }
                GridRow {
                    Text("Email:")
                        .frame(width: 50, alignment: .trailing)
                    TextField("", text: $email)
                        .textFieldStyle(.roundedBorder)
                        .focused($focusedField, equals: .email)
                }
            }
            .padding(.horizontal, 20)

            Divider()
                .padding(.top, 12)

            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button("Save") {
                    let p = Profile(id: profileId, label: label.trimmed, name: name.trimmed, email: email.trimmed)
                    onSave(p)
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(!isValid)
            }
            .padding(16)
        }
        .frame(width: 350)
        .onAppear {
            focusedField = .label
        }
    }
}

private extension String {
    var trimmed: String {
        trimmingCharacters(in: .whitespaces)
    }
}
