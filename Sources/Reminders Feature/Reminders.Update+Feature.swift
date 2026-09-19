public import ComposableArchitecture2
public import Interface_ComposableArchitecture
public import Reminders

@Interface_ComposableArchitecture.Feature
extension Reminders.Update: FeatureProtocol {
    public var body: some Feature {
        Editing(in: Reminders.self, \.editing)
    }
}
