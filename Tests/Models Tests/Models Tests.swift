import Foundation
import Models
import Tagged
import Testing

private struct Reminder {}
private struct Message {}

@Suite struct `Models types` {
    @Test func `a list is blank when its title is only whitespace`() {
        #expect(List<Reminder>(id: List<Reminder>.ID(UUID()), title: " \n").isBlank)
        #expect(!List<Reminder>(id: List<Reminder>.ID(UUID()), title: "Chores").isBlank)
    }

    @Test func `the default list is named and takes the default color`() {
        let id = List<Reminder>.ID(UUID())
        let list = List<Reminder>.default(id: id)
        #expect(list.id == id && list.title == "Personal" && list.color == .default)
    }

    @Test func `lists and tags of different elements have distinct identifiers`() {
        let uuid = UUID()
        #expect(ObjectIdentifier(List<Reminder>.ID.self) != ObjectIdentifier(List<Message>.ID.self))
        #expect(ObjectIdentifier(Models.Tag<Reminder>.self) != ObjectIdentifier(Models.Tag<Message>.self))
        #expect(List<Reminder>.ID(uuid).rawValue == List<Message>.ID(uuid).rawValue)
    }

    @Test func `a tag is its text and orders by it`() {
        let tag: Models.Tag<Reminder> = "car"
        #expect(tag.rawValue == "car" && tag.description == "car")
        #expect(Models.Tag<Reminder>("car") == tag && tag < "kids")
    }

    @Test func `an entry is identified by its list`() {
        let list = List<Reminder>(id: List<Reminder>.ID(UUID()), title: "Family")
        let entry = List<Reminder>.Entry(list: list, count: 3)
        #expect(entry.id == list.id && entry.count == 3)
    }

    @Test func `a window starts at one step, widens while there is more, and starts over for another key`() {
        let (step, margin) = (300, 60)
        var window = Window<String>(step: step, margin: margin)
        #expect(window.limit(for: "all") == step && window.limit(for: "today") == step)
        window.widen(for: "all", shown: step, total: step)
        #expect(window.limit(for: "all") == step)
        window.widen(for: "all", shown: step, total: step + 1)
        #expect(window.limit(for: "all") == 2 * step && window.limit(for: "today") == step)
        window.extend(for: "all", by: 1)
        #expect(window.limit(for: "all") == 2 * step + 1)
        window.open(for: "today")
        #expect(window.limit(for: "today") == nil && window.limit(for: "all") == step)
        window.widen(for: "today", shown: 10, total: 20)
        window.extend(for: "today", by: 1)
        #expect(window.limit(for: "today") == nil)
        #expect(window.nearsEnd(step - margin, of: step, total: step + 1))
        #expect(!window.nearsEnd(step - margin - 1, of: step, total: step + 1))
        #expect(!window.nearsEnd(step - 1, of: step, total: step))
    }

    @Test func `the default color has unit components`() {
        let color = Color.default
        #expect((0...1).contains(color.red) && (0...1).contains(color.green) && (0...1).contains(color.blue))
        #expect((color.red * 255).rounded() == 74 && (color.green * 255).rounded() == 153 && (color.blue * 255).rounded() == 239)
    }

    @Test func `colors round-trip through their hex`() {
        #expect(Color(Color.Hex(rawValue: 0x4a99ef)) == .default && Color.Hex(.default).rawValue == 0x4a99ef)
        #expect(Color.Hex(Color(red: 2, green: -1, blue: 0.5)).rawValue == 0xff0080)
    }
}
