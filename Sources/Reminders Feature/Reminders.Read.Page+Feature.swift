import Optic
public import ComposableArchitecture2
public import Interface_ComposableArchitecture
public import Reminders

@Interface_ComposableArchitecture.Feature
extension Reminders.Read.Page: FeatureProtocol {
    public var body: some Feature {
        Listing(
            self,
            rows: \.rows,
            commands: Reminders.self,
            editing: \.editing,
            deleting: \.delete?.id
        )
    }
}
