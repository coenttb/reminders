import Reminders
import Reminders_Interface
import Testing
import Tagged

@Suite struct `Reminder application rules` {
    @Test func `the grace period between the tap and completed is five seconds`() {
        #expect(Reminders.Pending.grace == .seconds(5))
    }

    @Test func `the search commits trimmed text as a token and leaves a tag prefix for the suggestions`() {
        var search = Reminders.Search(text: " Take ")
        search.commitText()
        #expect(search.tokens == [.near("Take")] && search.text.isEmpty)
        search.text = "#so"
        search.commitText()
        #expect(search.tokens == [.near("Take")] && search.text == "#so" && search.tagPrefix == "so")
        #expect(!Reminders.Search(text: "#so").matchesReminders)
        #expect(search.matchesReminders && search.matchedText.isEmpty)
        search.add(tag: "car")
        #expect(search.text.isEmpty && search.tags == ["car"] && search.isActive)
        #expect(!Reminders.Search().isActive)
    }

    @Test func `a window starts at one step, widens while there is more, and starts over for another key`() {
        var window = Window<Reminders.Filter>()
        let step = Window<Reminders.Filter>.step
        #expect(window.limit(for: .all) == step && window.limit(for: .today) == step)
        window.widen(for: .all, shown: step, total: step)
        #expect(window.limit(for: .all) == step)
        window.widen(for: .all, shown: step, total: step + 1)
        #expect(window.limit(for: .all) == 2 * step && window.limit(for: .today) == step)
        window.extend(for: .all, by: 1)
        #expect(window.limit(for: .all) == 2 * step + 1)
        window.open(for: .today)
        #expect(window.limit(for: .today) == nil && window.limit(for: .all) == step)
        window.widen(for: .today, shown: 10, total: 20)
        window.extend(for: .today, by: 1)
        #expect(window.limit(for: .today) == nil)
        let margin = Window<Reminders.Filter>.margin
        #expect(Window<Reminders.Filter>.nearsEnd(step - margin, of: step, total: step + 1))
        #expect(!Window<Reminders.Filter>.nearsEnd(step - margin - 1, of: step, total: step + 1))
        #expect(!Window<Reminders.Filter>.nearsEnd(step - 1, of: step, total: step))
    }
}
