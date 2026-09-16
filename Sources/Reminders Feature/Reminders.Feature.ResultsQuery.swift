import Reminders
import Reminders_Interface

extension Reminders.Feature {
    struct ResultsQuery: Equatable {
        var search: Reminders.Search
        var limit: Int?
    }
}
