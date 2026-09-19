// Aspirational syntax; see FEATURE-SYNTAX.md. Bridge support is not implemented.
public import Interface_ComposableArchitecture
public import Reminders

@Feature
extension Reminders.Read.Page {
    public var body: some Feature {
        Listing(
            self,
            rows: \.rows,
            commands: Reminders.self,
            editing: \.editing,
            deleting: \.delete?.id
        )
    }
}
