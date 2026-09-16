import Models
import Reminders
import Testing

@Suite struct `Reminders search query` {
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
}
