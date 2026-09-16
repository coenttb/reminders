public import Organizing
public import Reminders
public import Reminders_Interface
public import Reminders_SQL
public import SwiftUI

extension Organizing.List<Reminder>.Form {
    public struct SwiftUI {
        @Binding private var draft: Organizing.List<Reminder>.Record.Draft
        private var form: Organizing.List<Reminder>.Form
        @FocusState private var nameFocused: Bool
        @State private var discardPresented = false

        public init(draft: Binding<Organizing.List<Reminder>.Record.Draft>, form: Organizing.List<Reminder>.Form) {
            self._draft = draft
            self.form = form
        }
    }
}

extension Organizing.List<Reminder>.Form.SwiftUI: SwiftUI::View {
    public static var palette: [(name: String, color: Organizing.Color.Hex)] {
        [
            ("Red", rgb(255, 59, 48)), ("Orange", rgb(255, 149, 0)), ("Yellow", rgb(255, 204, 0)),
            ("Green", rgb(52, 199, 89)), ("Blue", Organizing.Color.Hex(Organizing.Color.default)), ("Purple", rgb(175, 82, 222)),
            ("Brown", rgb(162, 132, 94)),
        ]
    }

    private static func rgb(_ red: Int, _ green: Int, _ blue: Int) -> Organizing.Color.Hex {
        Organizing.Color.Hex(Organizing.Color(red: Double(red) / 255, green: Double(green) / 255, blue: Double(blue) / 255))
    }

    public var body: some SwiftUI::View {
        let color = SwiftUI::Color(Organizing.Color(draft.color))
        SwiftUI::Form {
            Section {
                VStack(spacing: 20) {
                    Organizing.List<Reminder>.Badge(color: color, size: 100)
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
                    ForEach(Self.palette, id: \.color) { name, hex in
                        Button {
                            draft.color = hex
                        } label: {
                            Circle()
                                .fill(SwiftUI::Color(Organizing.Color(hex)))
                                .frame(width: 40, height: 40)
                                .overlay {
                                    if hex == draft.color {
                                        Circle().strokeBorder(SwiftUI::Color(.systemGray3), lineWidth: 3).padding(-6)
                                    }
                                }
                                .contentShape(.circle)
                        }
                        .buttonStyle(.borderless)
                        .accessibilityLabel(name)
                        .accessibilityAddTraits(hex == draft.color ? .isSelected : [])
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
}
