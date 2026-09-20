import Optic
import DebugSnapshots
import CasePaths
public import ComposableArchitecture2
public import Interface_ComposableArchitecture
public import Reminders

@Interface_ComposableArchitecture.Feature
extension Reminders: FeatureProtocol {
    public var body: some Feature {
        Children(\.read, \.lists)
            .discard(\.read.page, matching: \.filter.list, before: \.lists?.delete?.id)
    }
}
