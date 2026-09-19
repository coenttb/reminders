import Optic
import DebugSnapshots
import CasePaths
public import ComposableArchitecture2
public import Interface_ComposableArchitecture
public import Reminders

@Interface_ComposableArchitecture.Feature
extension Reminders.Lists: FeatureProtocol {
    public var body: some Feature {
        Presenting(\.create)
    }
}
