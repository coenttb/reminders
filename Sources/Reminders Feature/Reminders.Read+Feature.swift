// Aspirational syntax; see FEATURE-SYNTAX.md. Bridge support is not implemented.
public import Interface_ComposableArchitecture
public import Reminders

@Feature
extension Reminders.Read {
    public var body: some Feature {
        Observing(self)
        Presenting(\.page)
    }
}
