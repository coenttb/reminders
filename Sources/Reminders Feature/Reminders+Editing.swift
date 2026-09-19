// Aspirational syntax; see FEATURE-SYNTAX.md. Bridge support is not implemented.
public import Interface_ComposableArchitecture
public import Reminders

extension Reminders {
    public var editing: some Feature {
        Editing(
            create: create,
            update: update,
            delete: delete,
            draft: \.draft,
            blank: .discardNewDeleteExisting(\.isBlank),
            ignoreUpdateFailure: .notFound
        )
    }
}
