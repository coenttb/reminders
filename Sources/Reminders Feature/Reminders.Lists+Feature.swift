import Optic
import DebugSnapshots
import CasePaths
public import ComposableArchitecture2
public import Interface_ComposableArchitecture
public import Reminders
import Operation

@FeatureComposition(
    .presented(Reminders.Lists.Structure.create.self),
    calls: Reminders.Lists.Call.self
)
extension Reminders.Lists: FeatureProtocol {}
