public import Dependencies
public import Reminders
public import Reminders_Session

extension DependencyValues {
    public var remindersSession: Reminders.Session.Client {
        get { self[Reminders.Session.Client.self] }
        set { self[Reminders.Session.Client.self] = newValue }
    }
}

extension Reminders.Session.Client: TestDependencyKey {
    public static var testValue: Reminders.Session.Client {
        .init(
            current: unimplemented("\\.remindersSession.current", placeholder: Reminders.Session()),
            setFilter: unimplemented("\\.remindersSession.setFilter"),
            setEditing: unimplemented("\\.remindersSession.setEditing")
        )
    }
}
