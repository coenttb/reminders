import Optic
import DebugSnapshots
import CasePaths
public import ComposableArchitecture2
import Interface_ComposableArchitecture
public import Reminders
import Operation

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
