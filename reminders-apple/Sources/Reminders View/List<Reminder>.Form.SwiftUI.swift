public import Models
public import Reminder
public import Reminders
public import SwiftUI

extension Models.List<Reminder>.Form {
    public struct SwiftUI {
        @Binding private var draft: Models.List<Reminder>
        private var form: Models.List<Reminder>.Form
        @FocusState private var nameFocused: Bool
        @State private var discardPresented = false

        public init(draft: Binding<Models.List<Reminder>>, form: Models.List<Reminder>.Form) {
            self._draft = draft
            self.form = form
        }
    }
}

extension Models.List<Reminder>.Form.SwiftUI: SwiftUI::View {
    public static var palette: [(name: String, color: Models.Color.Hex)] {
        [
            ("Red", rgb(255, 59, 48)), ("Orange", rgb(255, 149, 0)), ("Yellow", rgb(255, 204, 0)),
            ("Green", rgb(52, 199, 89)), ("Blue", Models.Color.Hex(Models.Color.default)), ("Purple", rgb(175, 82, 222)),
            ("Brown", rgb(162, 132, 94)),
        ]
    }

    private static func rgb(_ red: Int, _ green: Int, _ blue: Int) -> Models.Color.Hex {
        Models.Color.Hex(Models.Color(red: Double(red) / 255, green: Double(green) / 255, blue: Double(blue) / 255))
    }

    public var body: some SwiftUI::View {
        let color = SwiftUI::Color(draft.color)
        SwiftUI::Form {
            Section {
                VStack(spacing: 20) {
                    Models.List<Reminder>.Badge(color: color, size: 100)
                        .shadow(color: color.opacity(0.45), radius: 14, y: 6)
                    TextField("List Name", text: $draft.title)
                        .font(.title2.weight(.bold))
                        .foregroundStyle(color)
                        .multilineTextAlignment(.center)
                        .padding()
                        .textFieldStyle(.plain)
                        .background(SwiftUI::Color(.tertiarySystemFill), in: .rect(cornerRadius: 12))
                        .focused($nameFocused)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
            .listSectionMargins(.top, 6)
            Section {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 6), spacing: 14) {
                    ForEach(Self.palette, id: \.color) { entry in
                        swatch(entry.name, entry.color, selected: entry.color == Models.Color.Hex(draft.color))
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
            }
            if let failure = form.failure {
                Section { Text(failure).foregroundStyle(.red) } header: { Text("Not saved") }
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel", systemImage: "xmark") {
                    if form.isDirty { discardPresented = true } else { form.actions.cancel() }
                }
                .discardPrompt(discardTitle, isPresented: $discardPresented, discard: form.actions.cancel)
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Done", systemImage: "checkmark", action: form.actions.save)
                    .buttonStyle(.glassProminent)
                    .disabled(draft.isBlank)
            }
        }
        .onAppear { nameFocused = form.isNew }
    }

    public var discardTitle: String {
        form.isNew ? "Are you sure you want to discard this new list?" : "Are you sure you want to discard your changes?"
    }

    private func swatch(_ name: String, _ hex: Models.Color.Hex, selected: Bool) -> some SwiftUI::View {
        Button {
            draft.color = Models.Color(hex)
        } label: {
            Circle()
                .fill(SwiftUI::Color(Models.Color(hex)))
                .frame(width: 40, height: 40)
                .overlay {
                    if selected {
                        Circle().strokeBorder(SwiftUI::Color(.systemGray3), lineWidth: 3).padding(-6)
                    }
                }
                .contentShape(.circle)
        }
        .buttonStyle(.borderless)
        .accessibilityLabel(name)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}
