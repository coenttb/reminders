import Optic
import DebugSnapshots
import CasePaths
public import ComposableArchitecture2
public import Interface_ComposableArchitecture
public import Reminders
public import Reminder
import Operation

extension Reminders.Update: FeatureProtocol {
    public typealias State = Interface_ComposableArchitecture.Editing<Reminder>.State
    public typealias Action = Never
    public var body: some Feature {
        WithInterface(Reminders.self) { $0.editing }
    }
}
