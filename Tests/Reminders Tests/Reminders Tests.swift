import Foundation
import Models
import Reminder
import Reminders
import Testing
import Tagged

@Suite struct `Reminders rules` {
    let list = List<Reminder>.ID(UUID())

    @Test func `a filter narrows and closes as its tags and list go`() {
        #expect(Reminders.Filter.tags(["car", "kids"]).removing(tag: "car") == .tags(["kids"]))
        #expect(Reminders.Filter.tags(["kids"]).removing(tag: "kids") == nil)
        #expect(Reminders.Filter.today.removing(tag: "kids") == .today)
        #expect(Reminders.Filter.list(list).removing(list: list) == nil)
        #expect(Reminders.Filter.all.removing(list: list) == .all)
        #expect(Reminders.Filter.tags(["car", "kids"]) == .tags(["kids", "car"]))
    }

    @Test func `filters round-trip through their keys and colors through their hex`() {
        let id = List<Reminder>.ID(UUID())
        for filter in [Reminders.Filter.all, .completed, .flagged, .list(id), .scheduled, .tags(["a", "b, c"]), .today] {
            #expect(Reminders.Filter(key: Reminders.Filter.Key(filter)) == filter)
        }
        #expect(Reminders.Filter.Key(.tags(["b", "a"])) == Reminders.Filter.Key(.tags(["a", "b"])))
        #expect(Reminders.Filter.Key(.list(id)).rawValue == "list_\(id.rawValue.uuidString)")
        #expect(Reminders.Filter(key: Reminders.Filter.Key(rawValue: "list_not-a-uuid")) == nil)
        #expect(Color(Color.Hex(rawValue: 0x4a99ef)) == .default && Color.Hex(.default).rawValue == 0x4a99ef)
        #expect(Color.Hex(Color(red: 2, green: -1, blue: 0.5)).rawValue == 0xff0080)
    }
}
