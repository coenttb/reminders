import Foundation
import Reminders
import Reminders_View
import SwiftUI
import Tagged
import Testing

@Suite struct `Lists presentation` {
    @Test func `the home, detail, search, rows, forms, and picker construct from domain values`() {
        let now = Date(timeIntervalSince1970: 1_234_567_890)
        let lists = Lists.sample(at: now)
        let reminder = lists.reminders[0]
        _ = Lists.View(lists: lists, now: now, open: { _ in }, details: { _ in }, delete: { _ in }, move: { _, _ in }, deleteTag: { _ in })
        let rows = Reminder.Row.Actions(complete: { _ in }, delete: { _ in }, details: { _ in }, edit: { _ in })
        let editor = Reminder.Editor.Actions(complete: { _ in }, details: { _ in }, submit: {}, setDate: { _, _ in }, setTime: { _, _ in })
        _ = Lists.Detail.View(.today, lists: lists, now: now, draft: { _ in .constant(reminder) }, rows: rows, editor: editor, done: {}, backgroundTapped: {}, move: { _, _ in }, order: { _ in }, toggleCompleted: {}, newReminder: {})
        _ = Lists.Detail.View(.list(lists.orderedLists[0].id), lists: lists, now: now, draft: { _ in .constant(reminder) }, rows: rows, editor: editor, done: {}, backgroundTapped: {}, move: { _, _ in }, order: { _ in }, toggleCompleted: {}, newReminder: {})
        _ = Lists.Search.View(Lists.Search(text: "Take"), lists: lists, now: now, rows: rows, addTag: { _ in }, toggleCompleted: {}, deleteCompleted: { _ in })
        _ = Lists.Stats.Cell("Today", systemImage: "calendar.circle.fill", color: .blue, count: 2) {}
        _ = Reminder.Row(reminder, color: .blue, now: now, actions: rows)
        _ = Reminder.List.Row(lists.orderedLists[0], count: 4, details: {}, delete: {})
        _ = Tag.Row(lists.usedTags[0])
        _ = Reminder.Form(reminder: .constant(reminder), isNew: false, isDirty: true, lists: lists.orderedLists, tags: lists.rankedTags, now: now, addTag: { _ in }, renameTag: { _, _ in }, deleteTag: { _ in }, save: {}, cancel: {})
        _ = Reminder.List.Form(list: .constant(lists.orderedLists[0]), save: {}, cancel: {})
        _ = Tag.Picker(selection: .constant([]), tags: lists.rankedTags, add: { _ in }, rename: { _, _ in }, delete: { _ in })
    }

    @Test func `the due date reads as a day, a weekday, or a date, with the time only when it matters`() {
        let calendar = Calendar(identifier: .gregorian)
        let now = calendar.date(from: DateComponents(year: 2026, month: 9, day: 14, hour: 9))!
        let list = Reminder.List.ID(UUID())
        var reminder = Reminder(id: Reminder.ID(UUID()), list: list, title: "x", due: now)
        #expect(reminder.dueDescription(at: now, calendar: calendar) == "Today")
        reminder.due = calendar.date(byAdding: .day, value: 1, to: now)
        #expect(reminder.dueDescription(at: now, calendar: calendar) == "Tomorrow")
        reminder.due = calendar.date(byAdding: .day, value: 3, to: now)
        #expect(reminder.dueDescription(at: now, calendar: calendar) == reminder.due!.formatted(.dateTime.weekday(.wide)))
        reminder.due = calendar.date(byAdding: .day, value: 30, to: now)
        #expect(reminder.dueDescription(at: now, calendar: calendar) == reminder.due!.formatted(date: .abbreviated, time: .omitted))
        reminder.hasTime = true
        #expect(reminder.dueDescription(at: now, calendar: calendar)!.hasSuffix(reminder.due!.formatted(date: .omitted, time: .shortened)))
        reminder.set(due: nil)
        #expect(reminder.hasTime == false && reminder.dueDescription(at: now, calendar: calendar) == nil)
        // The week runs to six days out; the seventh is a date, and only one day back is Yesterday.
        reminder.due = calendar.date(byAdding: .day, value: 6, to: now)
        #expect(reminder.dueDescription(at: now, calendar: calendar) == reminder.due!.formatted(.dateTime.weekday(.wide)))
        reminder.due = calendar.date(byAdding: .day, value: 7, to: now)
        #expect(reminder.dueDescription(at: now, calendar: calendar) == reminder.due!.formatted(date: .abbreviated, time: .omitted))
        reminder.due = calendar.date(byAdding: .day, value: -1, to: now)
        #expect(reminder.dueDescription(at: now, calendar: calendar) == "Yesterday")
        reminder.due = calendar.date(byAdding: .day, value: -2, to: now)
        #expect(reminder.dueDescription(at: now, calendar: calendar) == reminder.due!.formatted(date: .abbreviated, time: .omitted))
    }

    @Test func `the list color round-trips through SwiftUI`() {
        let color = Reminder.List.Color(hex: 0xed8935)
        #expect(Reminder.List.Color(color.swiftUI).hex == color.hex)
        #expect(Lists.Detail.flagged.color(in: Lists.sample(at: Date(timeIntervalSince1970: 1_234_567_890))) == .orange)
    }
}
