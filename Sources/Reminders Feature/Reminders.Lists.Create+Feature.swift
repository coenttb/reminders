import Optic
import DebugSnapshots
import CasePaths
public import ComposableArchitecture2
public import Interface_ComposableArchitecture
public import Reminders
import Operation

extension Reminders.Lists.Create: FeatureProtocol {
    public typealias State = Requesting<Reminders.Lists.Create.Run>.State
    public typealias Action = Call
    public var body: some Feature { Requesting<Reminders.Lists.Create.Run>(self) }
}
