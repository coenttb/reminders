import Models
import Reminder
public import Reminders
public import Reminders_Sample
import Reminders_SQL
public import SQLiteData
import Standard_Library_Extensions
import Tagged

extension Reminders.Sample {
    public static func initialize(with sample: Self, in db: Database) throws {
        guard try List<Reminder>.Record.all.fetchCount(db) == 0, try Reminder.Record.all.fetchCount(db) == 0 else { return }
        try replace(with: sample, in: db)
    }

    public func initialize(in db: Database) throws { try Self.initialize(with: self, in: db) }

    public static func replace(with sample: Self, in db: Database) throws {
        try Reminders.Tagging.delete().execute(db)
        try Reminder.Record.delete().execute(db)
        try List<Reminder>.Record.delete().execute(db)
        try Tag<Reminder>.Record.delete().execute(db)
        try Reminders.Filter.Preference.Record.delete().execute(db)
        for lists in Array(sample.lists.enumerated()).chunks(of: 200) as [ArraySlice<(offset: Int, element: List<Reminder>)>] {
            try List<Reminder>.Record.insert { lists.map { List<Reminder>.Record($0.element, position: $0.offset) } }.execute(db)
        }
        for tags in sample.tags.sorted().chunks(of: 500) as [ArraySlice<Tag<Reminder>>] {
            try Tag<Reminder>.Record.insert { tags.map(Tag<Reminder>.Record.init) }.execute(db)
        }
        for reminders in Array(sample.reminders.enumerated()).chunks(of: 200) as [ArraySlice<(offset: Int, element: Reminder)>] {
            try Reminder.Record.insert { reminders.map { Reminder.Record.Draft($0.element, position: $0.offset) } }.execute(db)
        }
        let taggings = sample.reminders.flatMap { reminder in reminder.tags.sorted().map { Reminders.Tagging(reminderID: reminder.id, tagID: $0) } }
        for chunk in taggings.chunks(of: 500) as [ArraySlice<Reminders.Tagging>] {
            try Reminders.Tagging.insert { Array(chunk) }.execute(db)
        }
    }

    public func replace(in db: Database) throws { try Self.replace(with: self, in: db) }
}
