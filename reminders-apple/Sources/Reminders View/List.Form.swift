public import Organizing
public import SwiftUI

extension Organizing.List {
    public struct Form: SwiftUI.View {
        @Binding private var list: Organizing.List<Element>
        private var isNew: Bool
        private var isDirty: Bool
        private var failure: String?
        private var save: () -> Void
        private var cancel: () -> Void
        @FocusState private var nameFocused: Bool
        @State private var discardPresented = false

        public init(list: Binding<Organizing.List<Element>>, isNew: Bool = true, isDirty: Bool = false, failure: String? = nil, save: @escaping () -> Void, cancel: @escaping () -> Void) {
            self._list = list
            self.isNew = isNew
            self.isDirty = isDirty
            self.failure = failure
            self.save = save
            self.cancel = cancel
        }
    }
}

extension Organizing.List.Form {
    public static var palette: [(name: String, color: Organizing.Color)] {
        [
            ("Red", rgb(255, 59, 48)), ("Orange", rgb(255, 149, 0)), ("Yellow", rgb(255, 204, 0)),
            ("Green", rgb(52, 199, 89)), ("Blue", .default), ("Purple", rgb(175, 82, 222)),
            ("Brown", rgb(162, 132, 94)),
        ]
    }

    private static func rgb(_ red: Int, _ green: Int, _ blue: Int) -> Organizing.Color {
        Organizing.Color(red: Double(red) / 255, green: Double(green) / 255, blue: Double(blue) / 255)
    }

    public var body: some SwiftUI.View {
        SwiftUI.Form {
            Section {
                VStack(spacing: 20) {
                    Organizing.List<Element>.Badge(color: SwiftUI.Color(list.color), size: 100)
                        .shadow(color: SwiftUI.Color(list.color).opacity(0.45), radius: 14, y: 6)
                    TextField("List Name", text: $list.title)
                        .font(.title2.weight(.bold))
                        .foregroundStyle(SwiftUI.Color(list.color))
                        .multilineTextAlignment(.center)
                        .padding()
                        .textFieldStyle(.plain)
                        .background(SwiftUI.Color(.tertiarySystemFill), in: .rect(cornerRadius: 12))
                        .focused($nameFocused)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
            .listSectionMargins(.top, 6)
            Section {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 6), spacing: 14) {
                    ForEach(Self.palette, id: \.color) { name, color in
                        Button {
                            list.color = color
                        } label: {
                            Circle()
                                .fill(SwiftUI.Color(color))
                                .frame(width: 40, height: 40)
                                .overlay {
                                    if color == list.color {
                                        Circle().strokeBorder(SwiftUI.Color(.systemGray3), lineWidth: 3).padding(-6)
                                    }
                                }
                                .contentShape(.circle)
                        }
                        .buttonStyle(.borderless)
                        .accessibilityLabel(name)
                        .accessibilityAddTraits(color == list.color ? .isSelected : [])
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
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

    public var discardTitle: String {
        isNew ? "Are you sure you want to discard this new list?" : "Are you sure you want to discard your changes?"
    }
}
