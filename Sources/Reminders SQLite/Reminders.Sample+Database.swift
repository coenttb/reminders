import Models
import Reminder
public import Reminders
public import Reminders_Sample
import Reminders_SQL
public import SQLiteData
import Standard_Library_Extensions
import Tagged

extension Reminders.Sample {
    public func initialize(in db: Database) throws {
        guard try Models.List<Reminder>.Record.all.fetchCount(db) == 0, try Reminder.Record.all.fetchCount(db) == 0 else { return }
        try replace(in: db)
    }

    public func replace(in db: Database) throws {
        try Reminders.Tagging.delete().execute(db)
        try Reminder.Record.delete().execute(db)
        try Models.List<Reminder>.Record.delete().execute(db)
        try Tag<Reminder>.Record.delete().execute(db)
        try Reminders.Preference.Record.delete().execute(db)
        for chunk in Array(lists.enumerated()).chunks(of: 200) as [ArraySlice<(offset: Int, element: Models.List<Reminder>)>] {
            try Models.List<Reminder>.Record.insert { chunk.map { Models.List<Reminder>.Record($0.element, position: $0.offset) } }.execute(db)
        }
        for chunk in tags.sorted().chunks(of: 500) as [ArraySlice<Tag<Reminder>>] {
            try Tag<Reminder>.Record.insert { chunk.map(Tag<Reminder>.Record.init) }.execute(db)
        }
        for chunk in Array(reminders.enumerated()).chunks(of: 200) as [ArraySlice<(offset: Int, element: Reminder)>] {
            try Reminder.Record.insert { chunk.map { Reminder.Record.Draft($0.element, position: $0.offset) } }.execute(db)
        }
        let taggings = reminders.flatMap { reminder in reminder.tags.sorted().map { Reminders.Tagging(reminderID: reminder.id, tagID: $0) } }
        for chunk in taggings.chunks(of: 500) as [ArraySlice<Reminders.Tagging>] {
            try Reminders.Tagging.insert { Array(chunk) }.execute(db)
        }
    }
}
