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
        @Sendable func placement(_ id: Reminder.ID, in db: Database) throws -> Placement {
            guard let row = try Reminder.Record.find(id).rows().fetchOne(db) else { throw Read.Error.notFound }
            return Placement(row)
        }
        @Sendable func insert(_ draft: Reminder.Record.Draft, in db: Database) throws -> Reminder.ID {
            let inserted = Reminder.Record.insert { draft }
            guard let id = try inserted.returning(\.id).fetchOne(db) else {
                throw DatabaseError(message: "The reminder was not inserted.")
            }
            return id
        }
        return Self(
            create: .init { request in
                try database.write { db in
                    var draft = Reminder.Record.Draft(request.reminder)
                    let id: Reminder.ID
                    if let anchor = request.below {
                        try Reminder.Record.where { $0.position.gt(anchor.position) }.update { $0.position += 1 }.execute(db)
                        draft.position = anchor.position + 1
                        id = try insert(draft, in: db)
                    } else {
                        id = try insert(draft, in: db)
                        try Reminder.Record.find(id)
                            .update { $0.position = Reminder.Record.select { ($0.position.max() ?? -1) + 1 } }
                            .execute(db)
                    }
                    try Reminders.Tagging.attach(request.reminder.tags, to: id, in: db)
                    return try placement(id, in: db)
                }
            },
            read: .init(
                { _ in try database.read(Read.Today.Request(today: now).fetch) },
                today: { request in try database.read(request.fetch) },
                id: { request in try database.read { db in try placement(request.id, in: db) } },
                page: { request in try database.read(request.fetch) },
                search: { request in try database.read(request.fetch) },
                preference: { request in try database.read(request.fetch) }
            ),
            update: .init(
                { request in
                    try database.write { db in
                        let reminder = request.reminder
                        guard try Reminder.Record.find(reminder.id).fetchCount(db) > 0 else { throw Update.Error.notFound }
                        // The form writes its own columns; position belongs to the order and completion to the timer.
                        try Reminder.Record.insert {
                            Reminder.Record.Draft(reminder)
                        } onConflict: {
                            $0.id
                        } doUpdate: { row, excluded in
                            row.title = excluded.title
                            row.notes = excluded.notes
                            row.dueDate = excluded.dueDate
                            row.hasTime = excluded.hasTime
                            row.flagged = excluded.flagged
                            row.priority = excluded.priority
                            row.listID = excluded.listID
                            row.repeats = excluded.repeats
                            row.completed = excluded.completed
                        }
                        .execute(db)
                        let stored = Set(try Reminders.Tagging.where { $0.reminderID.eq(reminder.id) }.select(\.tagID).fetchAll(db))
                        let removed = stored.subtracting(reminder.tags)
                        if !removed.isEmpty {
                            try Reminders.Tagging.where { $0.reminderID.eq(reminder.id) && $0.tagID.in(removed) }.delete().execute(db)
                        }
                        try Reminders.Tagging.attach(reminder.tags.subtracting(stored), to: reminder.id, in: db)
                        return try placement(reminder.id, in: db)
                    }
                },
                order: { request in
                    try database.write { db in
                        try Preference.Record.insert {
                            Preference.Record(key: Filter.Key(request.filter), ordering: request.ordering, showCompleted: request.filter == .completed)
                        } onConflict: {
                            $0.key
                        } doUpdate: { row, excluded in
                            row.ordering = excluded.ordering
                        }
                        .execute(db)
                    }
                },
                show: { request in
                    try database.write { db in
                        try Preference.Record.insert {
                            Preference.Record(key: Filter.Key(request.filter), showCompleted: request.completed)
                        } onConflict: {
                            $0.key
                        } doUpdate: { row, excluded in
                            row.showCompleted = excluded.showCompleted
                        }
                        .execute(db)
                    }
                },
                reorder: { request in
                    try database.write { db in
                        // The moved rows trade the positions they already hold, so the rest of the table keeps its order.
                        let stored = Dictionary(uniqueKeysWithValues: try Reminder.Record.where { $0.id.in(request.ids) }.select { ($0.id, $0.position) }.fetchAll(db))
                        let ordered = request.ids.filter { stored[$0] != nil }
                        let positions = ordered.compactMap { stored[$0] }.sorted()
                        for (id, position) in zip(ordered, positions) where stored[id] != position {
                            try Reminder.Record.find(id).update { $0.position = position }.execute(db)
                        }
                        try Preference.Record.insert {
                            Preference.Record(key: Filter.Key(request.filter), ordering: .manual, showCompleted: request.filter == .completed)
                        } onConflict: {
                            $0.key
                        } doUpdate: { row, excluded in
                            row.ordering = excluded.ordering
                        }
                        .execute(db)
                    }
                }
            ),
            delete: .init(
                { request in try database.write { db in try Reminder.Record.find(request.id).delete().execute(db) } },
                completed: .init(
                    in: { request in
                        let today = calendar.day(containing: request.today)
                        try database.write { db in
                            try Reminder.Record.where { $0.isCompleted && $0.belongs(to: request.filter, today: today) }.delete().execute(db)
                        }
                    },
                    matching: { request in
                        try database.write { db in
                            try Reminder.Record
                                .where { $0.isCompleted && $0.matches(request.query) }
                                .where { if let cutoff = request.dueBefore { $0.dueDate.lt(Date?.some(cutoff)) } }
                                .delete()
                                .execute(db)
                        }
                    }
                )
            ),
            lists: .init(
                create: { request in
                    try database.write { db in
                        try Models.List<Reminder>.Record.insert { Models.List<Reminder>.Record(request.list) }.execute(db)
                        try Models.List<Reminder>.Record.find(request.list.id)
                            .update { $0.position = Models.List<Reminder>.Record.select { ($0.position.max() ?? -1) + 1 } }
                            .execute(db)
                    }
                },
                update: { request in
                    try database.write { db in
                        guard try Models.List<Reminder>.Record.find(request.list.id).fetchCount(db) > 0 else { throw Lists.Error.notFound }
                        try Models.List<Reminder>.Record.find(request.list.id).update {
                            $0.title = request.list.title
                            $0.color = Color.Hex(request.list.color)
                        }
                        .execute(db)
                    }
                },
                delete: { request in
                    try database.write { db in
                        try Models.List<Reminder>.Record.find(request.id).delete().execute(db)
                        try Models.List<Reminder>.Record.installDefault(request.replacement, in: db)
                    }
                },
                reorder: { request in
                    try database.write { db in
                        try Models.List<Reminder>.Record.where { $0.id.in(request.ids) }.update { row in
                            let places = Array(request.ids.enumerated())
                            guard let first = places.first else { return }
                            row.position = places.dropFirst()
                                .reduce(Case(row.id).when(first.element, then: first.offset)) { cases, place in
                                    cases.when(place.element, then: place.offset)
                                }
                                .else(row.position)
                        }
                        .execute(db)
                    }
                }
            ),
            tags: .init(
                create: { request in
                    try database.write { db in
                        guard let tag = try Tag<Reminder>.Record.add(request.title, in: db) else { throw Tags.Error.blank }
                        return tag
                    }
                },
                rename: { request in
                    try database.write { db in
                        guard !request.title.isEmpty else { throw Tags.Error.blank }
                        let titles = Tag<Reminder>.Record.where { $0.title.eq(request.tag.rawValue) }.select(\.title)
                        guard let stored = try titles.fetchAll(db).first else { throw Tags.Error.notFound }
                        let current = Tag<Reminder>(stored)
                        // Renaming onto an existing tag merges into it; the links move and the old tag goes.
                        let twins = Tag<Reminder>.Record.where { $0.title.eq(request.title) }.select(\.title)
                        if let existing = try twins.fetchAll(db).first, existing != stored {
                            let target = Tag<Reminder>(existing)
                            try Reminders.Tagging.insert {
                                ($0.reminderID, $0.tagID)
                            } select: {
                                Reminders.Tagging.where { $0.tagID.eq(current) }.select { ($0.reminderID, target) }
                            } onConflict: {
                                ($0.reminderID, $0.tagID)
                            }
                            .execute(db)
                            try Tag<Reminder>.Record.find(current.rawValue).delete().execute(db)
                            return target
                        }
                        let renamed = Tag<Reminder>(request.title)
                        try Tag<Reminder>.Record.find(current.rawValue).update { $0.title = request.title }.execute(db)
                        try Reminders.Tagging.where { $0.tagID.eq(current) }.update { $0.tagID = renamed }.execute(db)
                        return renamed
                    }
                },
                delete: { request in try database.write { db in try Tag<Reminder>.Record.find(request.tag.rawValue).delete().execute(db) } },
                suggest: { request in try database.read(request.fetch) }
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
