import Optic
import DebugSnapshots
import CasePaths
public import ComposableArchitecture2
public import Interface_ComposableArchitecture
public import Reminders
public import Operation

extension Reminders.Read.Page: FeatureProtocol {
    public typealias State = Listing<Reminders.Read.Page.Run, Reminders.Call>.State
    public typealias Action = Reminders.Call
    public var body: some Feature {
        WithInterface(Reminders.self) { reminders in
            Listing<Run, Reminders.Call>(
                self,
                commands: reminders,
                editing: reminders.editing,
                deleting: \.delete?.id
            )
        }
    }
}
