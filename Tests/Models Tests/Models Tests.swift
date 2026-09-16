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
        #expect(ObjectIdentifier(Tag<Reminder>.ID.self) != ObjectIdentifier(Tag<Message>.ID.self))
        #expect(List<Reminder>.ID(uuid).rawValue == List<Message>.ID(uuid).rawValue)
    }

    @Test func `a tag is its title and round-trips through its identifier`() {
        let tag = Tag<Reminder>(title: "car")
        #expect(tag.id == "car")
        #expect(Tag<Reminder>(tag.id) == tag)
    }

    @Test func `an entry is identified by its list`() {
        let list = List<Reminder>(id: List<Reminder>.ID(UUID()), title: "Family")
        let entry = List<Reminder>.Entry(list: list, count: 3)
        #expect(entry.id == list.id && entry.count == 3)
    }

    @Test func `the default color has unit components`() {
        let color = Color.default
        #expect((0...1).contains(color.red) && (0...1).contains(color.green) && (0...1).contains(color.blue))
        #expect((color.red * 255).rounded() == 74 && (color.green * 255).rounded() == 153 && (color.blue * 255).rounded() == 239)
    }
}
