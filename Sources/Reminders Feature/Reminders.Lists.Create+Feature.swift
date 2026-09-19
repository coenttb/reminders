public import ComposableArchitecture2
public import Interface_ComposableArchitecture
public import Reminders

@Interface_ComposableArchitecture.Feature
extension Reminders.Lists.Create: FeatureProtocol {
    public var body: some Feature {
        Requesting(self)
    }
}
