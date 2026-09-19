// Aspirational syntax; see FEATURE-SYNTAX.md. Bridge support is not implemented.
public import Interface_ComposableArchitecture
public import Reminders

@Feature
extension Reminders {
    public var body: some Feature {
        Features {
            Child(\.read)
            Child(\.lists)
        }
        .dismiss(\.read.page, matching: \.filter.list, before: \.lists.delete.id)
    }
}
