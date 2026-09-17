public import Dependencies
import Foundation
import Models
import Reminder
public import Reminders
public import Reminders_Dependency
import Reminders_SQL
public import SQLiteData
import Tagged

extension Reminders {
    public static func sqlite(_ database: any DatabaseWriter) -> Reminders {
        @Dependency(\.calendar) var calendar
        @Dependency(\.date.now) var now
        // The synchronous GRDB API: each operation is one transaction that completes before the closure returns.
        @Sendable func read<T>(_ body: (Database) throws -> T) throws -> T { try database.read(body) }
        @Sendable func write<T>(_ body: (Database) throws -> T) throws -> T { try database.write(body) }
        @Sendable func placement(_ id: Reminder.ID, in db: Database) throws -> Placement {
            guard let row = try Reminder.Record.find(id).rows().fetchOne(db) else { throw SQLite.Error.notFound }
            return Placement(row)
        }
        return Self(
            create: .init { request in
                try write { db in
                    var draft = Reminder.Record.Draft(request.reminder)
                    let id: Reminder.ID
                    if let anchor = request.below {
                        try Reminder.Record.makeRoom(after: anchor.position).execute(db)
                        draft.position = anchor.position + 1
                        id = try Reminder.Record.add(draft, in: db)
                    } else {
                        id = try Reminder.Record.append(draft, in: db)
                    }
                    try Reminders.Tagging.attach(request.reminder.tags, to: id, in: db)
                    return try placement(id, in: db)
                }
            },
            read: .init(
                { _ in try read(Reminders.Summary.Query(today: calendar.day(containing: now)).fetch) },
                today: { request in try read(Reminders.Summary.Query(request, calendar: calendar).fetch) },
                id: { request in try read { db in try placement(request.id, in: db) } },
                page: { request in try read(Reminders.Page.Query(request, calendar: calendar).fetch) },
                search: { request in try read(Reminders.Page.Query(request, calendar: calendar).fetch) },
                preference: { request in try read(Reminders.Preference.Query(request).fetch) }
            ),
            update: .init(
                { request in
                    try write { db in
                        guard try Reminder.Record.save(Reminder.Record.Draft(request.reminder), tags: request.reminder.tags, isNew: false, in: db) != nil else { throw SQLite.Error.notFound }
                        try Reminder.Record.complete(request.reminder.id, request.reminder.completed).execute(db)
                        return try placement(request.reminder.id, in: db)
                    }
                },
                order: { request in
                    try write { db in try Preference.Record.set(ordering: request.ordering, for: request.filter).execute(db) }
                },
                show: { request in
                    try write { db in try Preference.Record.set(showCompleted: request.completed, for: request.filter).execute(db) }
                },
                reorder: { request in
                    try write { db in
                        try Reminder.Record.reorder(request.ids, in: db)
                        try Preference.Record.set(ordering: .manual, for: request.filter).execute(db)
                    }
                }
            ),
            delete: .init(
                { request in try write { db in try Reminder.Record.find(request.id).delete().execute(db) } },
                completed: .init(
                    in: { request in
                        try write { db in
                            try Reminder.Record.deleteCompleted(in: request.filter, today: calendar.day(containing: request.today)).execute(db)
                        }
                    },
                    matching: { request in
                        try write { db in
                            try Reminder.Record.deleteCompleted(matching: request.query, dueBefore: request.dueBefore).execute(db)
                        }
                    }
                )
            ),
            lists: .init(
                create: { request in
                    try write { db in
                        try Models.List<Reminder>.Record.insert { Models.List<Reminder>.Record(request.list) }.execute(db)
                        try Models.List<Reminder>.Record.placeLast(request.list.id).execute(db)
                    }
                },
                update: { request in
                    try write { db in
                        guard try Models.List<Reminder>.Record.find(request.list.id).fetchCount(db) > 0 else { throw SQLite.Error.notFound }
                        try Models.List<Reminder>.Record.save(Models.List<Reminder>.Record.Draft(Models.List<Reminder>.Record(request.list))).execute(db)
                    }
                },
                delete: { request in
                    try write { db in try Models.List<Reminder>.Record.delete(request.id, replacement: request.replacement, in: db) }
                },
                reorder: { request in
                    try write { db in try Models.List<Reminder>.Record.reorder(request.ids).execute(db) }
                }
            ),
            tags: .init(
                create: { request in
                    try write { db in
                        guard let tag = try Tag<Reminder>.Record.add(request.title, in: db) else { throw SQLite.Error.blank }
                        return tag
                    }
                },
                rename: { request in
                    try write { db in
                        guard !request.title.isEmpty else { throw SQLite.Error.blank }
                        guard let tag = try Tag<Reminder>.Record.rename(request.tag, to: request.title, in: db) else { throw SQLite.Error.notFound }
                        return tag
                    }
                },
                delete: { request in try write { db in try Tag<Reminder>.Record.delete(request.tag).execute(db) } },
                suggest: { request in try read(Reminders.Tags.Query(request).fetch) }
            )
        )
    }
}

extension Reminders: DependencyKey {
    public static var liveValue: Reminders {
        @Dependency(\.defaultDatabase) var database
        return .sqlite(database)
    }
}
