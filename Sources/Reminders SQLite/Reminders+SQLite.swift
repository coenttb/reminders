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
        return Self(
            list: .init(client: .init { request in try read(request.fetch) }),
            retrieve: .init(client: .init { id in
                try read { db in try Reminder.Record.find(id).rows().fetchOne(db).map(Placement.init) }
            }),
            start: .init(client: .init { request in
                try write { db in
                    var draft = Reminder.Record.Draft.start(in: request.list, created: request.created)
                    let id: Reminder.ID
                    if let anchor = request.below {
                        try Reminder.Record.makeRoom(after: anchor.position).execute(db)
                        draft.position = anchor.position + 1
                        id = try Reminder.Record.add(draft, in: db)
                    } else {
                        id = try Reminder.Record.append(draft, in: db)
                    }
                    return try Reminder.Record.find(id).rows().fetchOne(db).map(Placement.init)
                }
            }),
            create: .init(client: .init { reminder in
                try write { db in try Reminder.Record.save(Reminder.Record.Draft(reminder), tags: reminder.tags, isNew: true, in: db) != nil }
            }),
            update: .init(client: .init { reminder in
                try write { db in try Reminder.Record.save(Reminder.Record.Draft(reminder), tags: reminder.tags, isNew: false, in: db) != nil }
            }),
            toggle: .init(client: .init { id in
                try write { db in
                    try Reminder.Record.toggle(id).execute(db)
                    return try Reminder.Record.find(id).select(\.completed).fetchOne(db)
                }
            }),
            delete: .init(client: .init { id in
                try write { db in try Reminder.Record.find(id).delete().execute(db) }
            }),
            reorder: .init(client: .init { request in
                try write { db in
                    try Reminder.Record.reorder(request.ids, in: db)
                    try Preference.Record.set(ordering: .manual, for: request.filter).execute(db)
                }
            }),
            deleteCompleted: .init(client: .init { request in
                try write { db in try Reminder.Record.deleteCompleted(in: request.selection, today: request.today, dueBefore: request.dueBefore).execute(db) }
            }),
            overview: Overview(fetch: .init(client: .init { request in try read(request.fetch) })),
            lists: Lists(
                create: .init(client: .init { list in
                    try write { db in
                        try Models.List<Reminder>.Record.insert { Models.List<Reminder>.Record(list) }.execute(db)
                        try Models.List<Reminder>.Record.placeLast(list.id).execute(db)
                    }
                }),
                update: .init(client: .init { list in
                    try write { db in
                        guard try Models.List<Reminder>.Record.find(list.id).fetchCount(db) > 0 else { return false }
                        try Models.List<Reminder>.Record.save(Models.List<Reminder>.Record.Draft(Models.List<Reminder>.Record(list))).execute(db)
                        return true
                    }
                }),
                delete: .init(client: .init { request in
                    try write { db in try Models.List<Reminder>.Record.delete(request.id, replacement: request.replacement, in: db) }
                }),
                reorder: .init(client: .init { ids in
                    try write { db in try Models.List<Reminder>.Record.reorder(ids).execute(db) }
                })
            ),
            tags: Tags(
                create: .init(client: .init { title in try write { db in try Tag<Reminder>.Record.add(title, in: db) } }),
                update: .init(client: .init { request in try write { db in try Tag<Reminder>.Record.rename(request.tag, to: request.title, in: db) } }),
                delete: .init(client: .init { id in try write { db in try Tag<Reminder>.Record.delete(id).execute(db) } }),
                list: .init(client: .init { request in try read(request.fetch) })
            ),
            preferences: Preferences(
                ordering: .init(client: .init { request in try write { db in try Preference.Record.set(ordering: request.ordering, for: request.filter).execute(db) } }),
                toggleShowCompleted: .init(client: .init { filter in try write { db in try Preference.Record.toggleShowCompleted(for: filter).execute(db) } })
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
