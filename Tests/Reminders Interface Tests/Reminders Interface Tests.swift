import Reminders
import Reminders_Interface
import Testing
import Tagged

@Suite struct `Reminders interface` {
    @Test func `the search commits trimmed text as a token and leaves a tag prefix for the suggestions`() {
        var search = Reminders.Search.Query(text: " Take ")
        search.commitText()
        #expect(search.tokens == [.near("Take")] && search.text.isEmpty)
        search.text = "#so"
        search.commitText()
        #expect(search.tokens == [.near("Take")] && search.text == "#so" && search.tagPrefix == "so")
        #expect(!Reminders.Search.Query(text: "#so").matchesReminders)
        #expect(search.matchesReminders && search.matchedText.isEmpty)
        search.add(tag: "car")
        #expect(search.text.isEmpty && search.tags == ["car"] && search.isActive)
        #expect(!Reminders.Search.Query().isActive)
    }

    @Test func `a window starts at one step, widens while there is more, and starts over for another key`() {
        let (step, margin) = (300, 60)
        var window = Window<Reminders.Filter>(step: step, margin: margin)
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
        #expect(window.nearsEnd(step - margin, of: step, total: step + 1))
        #expect(!window.nearsEnd(step - margin - 1, of: step, total: step + 1))
        #expect(!window.nearsEnd(step - 1, of: step, total: step))
    }
}
