import Foundation
import Reminders

extension Reminders.Feature {
    struct DetailQuery: Equatable {
        var filter: Reminders.Filter?
        var place: Reminder?
        var today: Range<Date>?
        var limit: Int?
    }
}
