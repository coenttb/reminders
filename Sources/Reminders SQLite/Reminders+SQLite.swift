public import Dependencies
import Models
import Reminder
public import Reminders
public import Reminders_Dependency
import Reminders_SQL
public import SQLiteData
import Tagged

extension Reminders {
    public static func sqlite(_ database: any DatabaseWriter) -> Reminders {
        // The synchronous GRDB API: each operation is one transaction that completes before the closure returns.
        @Sendable func read<T>(_ body: (Database) throws -> T) throws -> T { try database.read(body) }
        @Sendable func write<T>(_ body: (Database) throws -> T) throws -> T { try database.write(body) }
        @Sendable func placement(_ id: Reminder.ID, in db: Database) throws -> Placement {
            guard let row = try Reminder.Record.find(id).rows().fetchOne(db) else { throw Error.notFound }
            return Placement(row)
        }
        return Self(
            create: { request in
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
            retrieve: { request in try read { db in try placement(request.id, in: db) } },
            update: { request in
                try write { db in
                    guard try Reminder.Record.save(Reminder.Record.Draft(request.reminder), tags: request.reminder.tags, isNew: false, in: db) != nil else { throw Error.notFound }
                    return try placement(request.reminder.id, in: db)
                }
            },
            delete: { request in
                try write { db in try Reminder.Record.find(request.id).delete().execute(db) }
            },
            list: { request in try read(Reminders.Page.Query(request).fetch) },
            reorder: { request in
                try write { db in
                    try Reminder.Record.reorder(request.ids, in: db)
                    try Preference.Record.set(ordering: .manual, for: request.filter).execute(db)
                }
            },
            complete: { request in try write { db in try Reminder.Record.complete(request.id).execute(db) } },
            reopen: { request in try write { db in try Reminder.Record.complete(request.id, false).execute(db) } },
            deleteCompleted: { request in
                try write { db in
                    switch request.completed {
                    case let .filter(filter, today):
                        try Reminder.Record.deleteCompleted(in: filter, today: today).execute(db)
                    case let .search(query, cutoff):
                        try Reminder.Record.deleteCompleted(matching: query, dueBefore: cutoff).execute(db)
                    }
                }
            },
            overview: { request in try read(Reminders.Summary.Query(request).fetch) },
            lists: .init(
                create: { request in
                    try write { db in
                        try Models.List<Reminder>.Record.insert { Models.List<Reminder>.Record(request.list) }.execute(db)
                        try Models.List<Reminder>.Record.placeLast(request.list.id).execute(db)
                    }
                },
                update: { request in
                    try write { db in
                        guard try Models.List<Reminder>.Record.find(request.list.id).fetchCount(db) > 0 else { throw Error.notFound }
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
                        guard let tag = try Tag<Reminder>.Record.add(request.title, in: db) else { throw Error.blank }
                        return tag
                    }
                },
                update: { request in
                    try write { db in
                        guard !request.title.isEmpty else { throw Error.blank }
                        guard let tag = try Tag<Reminder>.Record.rename(request.tag, to: request.title, in: db) else { throw Error.notFound }
                        return tag
                    }
                },
                delete: { request in try write { db in try Tag<Reminder>.Record.delete(request.tag).execute(db) } },
                list: { request in try read(Reminders.Tags.Query(request).fetch) }
            ),
            preferences: .init(
                update: { request in
                    try write { db in
                        switch request.change {
                        case let .ordering(ordering): try Preference.Record.set(ordering: ordering, for: request.filter).execute(db)
                        case .toggleShowCompleted: try Preference.Record.toggleShowCompleted(for: request.filter).execute(db)
                        }
                    }
                }
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
