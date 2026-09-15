public import Reminders
public import SwiftUI

extension Reminder.List {
    /// The sheet that creates or edits a list: the badge preview, the name in the
    /// list's color, and a palette of colors. Done is disabled until the name has
    /// text; dismissing an edited draft asks first.
    public struct Form: SwiftUI.View {
        @Binding private var list: Reminder.List
        private var isNew: Bool
        private var isDirty: Bool
        private var failure: String?
        private var save: () -> Void
        private var cancel: () -> Void
        @FocusState private var nameFocused: Bool
        @State private var discardPresented = false

        public init(list: Binding<Reminder.List>, isNew: Bool = true, isDirty: Bool = false, failure: String? = nil, save: @escaping () -> Void, cancel: @escaping () -> Void) {
            self._list = list
            self.isNew = isNew
            self.isDirty = isDirty
            self.failure = failure
            self.save = save
            self.cancel = cancel
        }
    }
}

extension Reminder.List.Form {
    /// The seven colors iOS 27 Reminders offers.
    public static let palette: [(name: String, color: Reminder.List.Color)] = [
        ("Red", Reminder.List.Color(hex: 0xff3b30)), ("Orange", Reminder.List.Color(hex: 0xff9500)), ("Yellow", Reminder.List.Color(hex: 0xffcc00)),
        ("Green", Reminder.List.Color(hex: 0x34c759)), ("Blue", Reminder.List.Color(hex: 0x4a99ef)), ("Purple", Reminder.List.Color(hex: 0xaf52de)),
        ("Brown", Reminder.List.Color(hex: 0xa2845e)),
    ]

    public var body: some SwiftUI.View {
        SwiftUI.Form {
            Section {
                VStack(spacing: 20) {
                    Reminder.List.Badge(color: list.color.swiftUI, size: 96)
                        .shadow(color: list.color.swiftUI.opacity(0.4), radius: 12, y: 6)
                    TextField("List Name", text: $list.title)
                        .font(.title2.weight(.bold))
                        .foregroundStyle(list.color.swiftUI)
                        .multilineTextAlignment(.center)
                        .padding()
                        .textFieldStyle(.plain)
                        .background(Color(.tertiarySystemFill), in: .rect(cornerRadius: 12))
                        .focused($nameFocused)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
            Section {
                LazyVGrid(columns: Array(repeating: GridItem(.fixed(48), spacing: 4), count: 6), spacing: 12) {
                    ForEach(Self.palette, id: \.color.hex) { name, color in
                        Button {
                            list.color = color
                        } label: {
                            Circle()
                                .fill(color.swiftUI.gradient)
                                .padding(4)
                                .overlay {
                                    if color == list.color {
                                        Circle().strokeBorder(Color(.systemGray3), lineWidth: 3)
                                    }
                                }
                                .frame(width: 48, height: 48)
                                .contentShape(.circle)
                        }
                        .buttonStyle(.borderless)
                        .accessibilityLabel(name)
                        .accessibilityAddTraits(color == list.color ? .isSelected : [])
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)
                ColorPicker("Custom", selection: $list.color.swiftUI)
            }
            if let failure {
                Section { Text(failure).foregroundStyle(.red) } header: { Text("Not saved") }
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel", systemImage: "xmark") {
                    if isDirty { discardPresented = true } else { cancel() }
                }
                .discardPrompt(discardTitle, isPresented: $discardPresented, discard: cancel)
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Done", systemImage: "checkmark", action: save)
                    .buttonStyle(.glassProminent)
                    .disabled(list.isBlank)
            }
        }
        .onAppear { nameFocused = isNew }
    }

    /// The question the sheet asks before an edited draft is discarded.
    public var discardTitle: String {
        isNew ? "Are you sure you want to discard this new list?" : "Are you sure you want to discard your changes?"
    }
}
