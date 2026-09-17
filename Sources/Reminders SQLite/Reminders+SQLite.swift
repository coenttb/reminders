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
            create: .init(client: .init { request in
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
            }),
            retrieve: .init(client: .init { id in try read { db in try placement(id, in: db) } }),
            update: .init(client: .init { reminder in
                try write { db in
                    guard try Reminder.Record.save(Reminder.Record.Draft(reminder), tags: reminder.tags, isNew: false, in: db) != nil else { throw Error.notFound }
                    return try placement(reminder.id, in: db)
                }
            }),
            delete: .init(client: .init { id in
                try write { db in try Reminder.Record.find(id).delete().execute(db) }
            }),
            list: .init(client: .init { request in try read(request.fetch) }),
            reorder: .init(client: .init { request in
                try write { db in
                    try Reminder.Record.reorder(request.ids, in: db)
                    try Preference.Record.set(ordering: .manual, for: request.filter).execute(db)
                }
            }),
            complete: .init(client: .init { id in try write { db in try Reminder.Record.complete(id).execute(db) } }),
            reopen: .init(client: .init { id in try write { db in try Reminder.Record.complete(id, false).execute(db) } }),
            deleteCompleted: .init(client: .init { request in
                try write { db in
                    switch request {
                    case let .filter(filter, today):
                        try Reminder.Record.deleteCompleted(in: filter, today: today).execute(db)
                    case let .search(query, cutoff):
                        try Reminder.Record.deleteCompleted(matching: query, dueBefore: cutoff).execute(db)
                    }
                }
            }),
            overview: .init(client: .init { request in try read(request.fetch) }),
            lists: Lists(product: .init(
                create: { list in
                    try write { db in
                        try Models.List<Reminder>.Record.insert { Models.List<Reminder>.Record(list) }.execute(db)
                        try Models.List<Reminder>.Record.placeLast(list.id).execute(db)
                    }
                },
                update: { list in
                    try write { db in
                        guard try Models.List<Reminder>.Record.find(list.id).fetchCount(db) > 0 else { throw Error.notFound }
                        try Models.List<Reminder>.Record.save(Models.List<Reminder>.Record.Draft(Models.List<Reminder>.Record(list))).execute(db)
                    }
                },
                delete: { id, replacement in
                    try write { db in try Models.List<Reminder>.Record.delete(id, replacement: replacement, in: db) }
                },
                reorder: { ids in
                    try write { db in try Models.List<Reminder>.Record.reorder(ids).execute(db) }
                }
            )),
            tags: Tags(
                create: .init(client: .init { title in
                    try write { db in
                        guard let tag = try Tag<Reminder>.Record.add(title, in: db) else { throw Error.blank }
                        return tag
                    }
                }),
                update: .init(client: .init { request in
                    try write { db in
                        guard !request.title.isEmpty else { throw Error.blank }
                        guard let tag = try Tag<Reminder>.Record.rename(request.tag, to: request.title, in: db) else { throw Error.notFound }
                        return tag
                    }
                }),
                delete: .init(client: .init { id in try write { db in try Tag<Reminder>.Record.delete(id).execute(db) } }),
                list: .init(client: .init { request in try read(request.fetch) })
            ),
            preferences: Preferences(
                update: .init(client: .init { request in
                    try write { db in
                        switch request.change {
                        case let .ordering(ordering): try Preference.Record.set(ordering: ordering, for: request.filter).execute(db)
                        case .toggleShowCompleted: try Preference.Record.toggleShowCompleted(for: request.filter).execute(db)
                        }
                    }
                })
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
