import Optic
import DebugSnapshots
import CasePaths
public import ComposableArchitecture2
public import Interface_ComposableArchitecture
public import Reminders

@Interface_ComposableArchitecture.Feature
extension Reminders.Read: FeatureProtocol {
    public var body: some Feature {
        // What the read delivers lands animated, as sqlite-data's animated fetches do, whoever wrote it.
        Observing(self).animation()
        Presenting(\.page)
    }
}
