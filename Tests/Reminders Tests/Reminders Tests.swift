import Foundation
import Models
import Reminder
import Reminders
import Testing
import Tagged

@Suite struct `Reminders values` {
    @Test func `a tags filter is the set of its tags`() {
        #expect(Reminders.Filter.tags(["car", "kids"]) == .tags(["kids", "car"]))
    }

    @Test func `the Completed smart list is the only one that shows completed reminders by default`() {
        #expect(Reminders.Preference.default(for: .completed) == Reminders.Preference(ordering: .dueDate, showCompleted: true))
        #expect(Reminders.Preference.default(for: .today) == Reminders.Preference())
    }
}
