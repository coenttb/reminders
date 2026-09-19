import Optic
import DebugSnapshots
import CasePaths
public import ComposableArchitecture2
public import Interface_ComposableArchitecture
public import Reminders
public import Reminder
public import Operation

// The domain supplies the coordinates. This application selects their lifetimes.
@FeatureComposition(
    .required(Reminders.Structure.read.self),
    .required(Reminders.Structure.lists.self),
    calls: Reminders.Call.self
)
extension Reminders {}

extension Reminders: FeatureProtocol {
    public var body: some Feature {
        Features {
            ComposableArchitecture2.Update { state, action in
                // A list can be deleted at the root or through its scoped interface.
                // Both close its page before execution; page calls keep their own lifetime.
                let deleted = action.call?.lists?.delete?.id ?? action.lists?.call?.delete?.id
                if let id = deleted, state.read.page?.list == id {
                    state.read.page = nil
                }
            }
            composition
        }
    }
}

@FeatureComposition(
    .observing(Reminders.Read.Run.self),
    .presented(Reminders.Read.Structure.page.self)
)
extension Reminders.Read: FeatureProtocol {}

@FeatureComposition(
    .presented(Reminders.Lists.Structure.create.self),
    calls: Reminders.Lists.Call.self
)
extension Reminders.Lists: FeatureProtocol {}

// Leaf interpretations reuse their existing state and canonical calls verbatim.
extension Reminders.Lists.Create: FeatureProtocol {
    public typealias State = Requesting<Reminders.Lists.Create.Run>.State
    public typealias Action = Call
    public var body: some Feature { Requesting<Reminders.Lists.Create.Run>(self) }
}

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

extension Reminders.Update: FeatureProtocol {
    public typealias State = Interface_ComposableArchitecture.Editing<Reminder>.State
    public typealias Action = Never
    public var body: some Feature {
        WithInterface(Reminders.self) { $0.editing }
    }
}
