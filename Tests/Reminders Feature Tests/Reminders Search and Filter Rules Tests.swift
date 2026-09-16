import Foundation
import Models
import Reminder
import Reminders
import Reminders_Feature
import Testing
import Tagged

@Suite struct `Reminders search and filter rules` {
    let list = List<Reminder>.ID(UUID())

    @Test func `the search field commits trimmed text as a term, keeps a tag prefix for the suggestions, and searches by what is committed`() {
        var search = Reminders.Search.Field(text: " Take ")
        #expect(search.selection == .search(Reminders.Search.Query(terms: [" Take "])))
        search.commitText()
        #expect(search.tokens == [.near("Take")] && search.text.isEmpty)
        #expect(search.query == Reminders.Search.Query(terms: ["Take"]))
        search.text = "#so"
        search.commitText()
        #expect(search.tokens == [.near("Take")] && search.text == "#so" && search.tagPrefix == "so")
        #expect(search.suggestions == Reminders.Tags.Client.Suggest.Request(prefix: "so", excluding: []))
        #expect(Reminders.Search.Field(text: "#so").selection == nil)
        #expect(search.selection == .search(Reminders.Search.Query(terms: ["Take"])))
        search.add(tag: "car")
        #expect(search.text.isEmpty && search.tags == ["car"] && search.isActive)
        #expect(search.selection == .search(Reminders.Search.Query(terms: ["Take"], tags: ["car"])))
        #expect(!Reminders.Search.Field().isActive && Reminders.Search.Field().selection == nil)
    }

    @Test func `a filter narrows and closes as its tags and list go`() {
        #expect(Reminders.Filter.tags(["car", "kids"]).removing(tag: "car") == .tags(["kids"]))
        #expect(Reminders.Filter.tags(["kids"]).removing(tag: "kids") == nil)
        #expect(Reminders.Filter.today.removing(tag: "kids") == .today)
        #expect(Reminders.Filter.list(list).removing(list: list) == nil)
        #expect(Reminders.Filter.all.removing(list: list) == .all)
    }

    @Test func `an overview finds a list by id and derives the tags in use in case-insensitive order`() {
        let personal = List<Reminder>(id: list, title: "Personal")
        let overview = Reminders.Overview.Client.Fetch.Result(
            lists: [List<Reminder>.Entry(list: personal, count: 2)],
            tags: [Tag<Reminder>.Entry(tag: "social", count: 3), Tag<Reminder>.Entry(tag: "Adulting", count: 1), Tag<Reminder>.Entry(tag: "car", count: 0)]
        )
        #expect(overview.list(list) == personal && overview.list(List<Reminder>.ID(UUID())) == nil)
        #expect(overview.rankedTags.map(\.rawValue) == ["social", "Adulting", "car"])
        #expect(overview.usedTags.map(\.rawValue) == ["Adulting", "social"])
    }
}
