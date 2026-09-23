import Optic
public import ComposableArchitecture2
public import Interface_ComposableArchitecture
public import Reminders

@Interface_ComposableArchitecture.Feature
extension Reminders.Read.Page: FeatureProtocol {
    public var body: some Feature {
        // The rows land animated, as sqlite-data's animated fetches do: a reminder that is added, or leaves the
        // page, does so animated, whoever wrote it.
        Listing(
            self,
            rows: \.rows,
            editing: \Reminders.editing
        )
        .animation()
    }
}
