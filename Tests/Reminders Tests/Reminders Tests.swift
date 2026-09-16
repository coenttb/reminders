import Foundation
import Models
import Reminder
import Reminders
import Testing
import Tagged

@Suite struct `Reminders values` {
    @Test func `a search query reads a tag prefix, matched text, and its tags from its text and tokens`() {
        #expect(!Reminders.Search.Query().isActive)
        let prefix = Reminders.Search.Query(text: "#so")
        #expect(prefix.isActive && prefix.tagPrefix == "so" && !prefix.matchesReminders && prefix.matchedText.isEmpty)
        let text = Reminders.Search.Query(text: "Take")
        #expect(text.tagPrefix == nil && text.matchesReminders && text.matchedText == "Take")
        let tokens = Reminders.Search.Query(text: "#so", tokens: [.near("Take"), .tag("car")])
        #expect(tokens.matchesReminders && tokens.matchedText.isEmpty && tokens.tags == ["car"])
    }

    @Test func `a tags filter is the set of its tags`() {
        #expect(Reminders.Filter.tags(["car", "kids"]) == .tags(["kids", "car"]))
    }
}
