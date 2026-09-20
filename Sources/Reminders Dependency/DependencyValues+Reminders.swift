public import Dependencies
import Interface_Dependencies
public import Reminders

extension DependencyValues {
    public var reminders: Reminders {
        get { self[Reminders.self] }
        set { self[Reminders.self] = newValue }
    }
}

@TestDependency(streams: .finished)
extension Reminders: TestDependencyKey {}
