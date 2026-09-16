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
        return Reminders(
            overview: Overview(client: Overview.Client { request in try read(request.fetch) }),
            listing: Listing(client: Listing.Client { request in try read(request.fetch) }),
            editor: Editor(
                client: Editor.Client(
                    reminder: { id in
                        try read { db in try Reminder.Record.find(id).rows().fetchOne(db).map(Placement.init) }
                    },
                    start: { list, anchor, created in
                        try write { db in
                            var draft = Reminder.Record.Draft.start(in: list, created: created)
                            let id: Reminder.ID
                            if let anchor {
                                try Reminder.Record.makeRoom(after: anchor.position).execute(db)
                                draft.position = anchor.position + 1
                                id = try Reminder.Record.add(draft, in: db)
                            } else {
                                id = try Reminder.Record.append(draft, in: db)
                            }
                            return try Reminder.Record.find(id).rows().fetchOne(db).map(Placement.init)
                        }
                    },
                    add: { reminder in
                        try write { db in try Reminder.Record.save(Reminder.Record.Draft(reminder), tags: reminder.tags, isNew: true, in: db) != nil }
                    },
                    update: { reminder in
                        try write { db in try Reminder.Record.save(Reminder.Record.Draft(reminder), tags: reminder.tags, isNew: false, in: db) != nil }
                    },
                    toggle: { id in
                        try write { db in
                            try Reminder.Record.toggle(id).execute(db)
                            return try Reminder.Record.find(id).select(\.completed).fetchOne(db)
                        }
                    },
                    delete: { id in
                        try write { db in try Reminder.Record.find(id).delete().execute(db) }
                    },
                    move: { ids, filter in
                        try write { db in
                            try Reminder.Record.reorder(ids, in: db)
                            try Preference.Record.set(ordering: .manual, for: filter).execute(db)
                        }
                    },
                    deleteCompleted: { selection, today, cutoff in
                        try write { db in try Reminder.Record.deleteCompleted(in: selection, today: today, dueBefore: cutoff).execute(db) }
                    }
                )
            ),
            lists: Lists(
                client: Lists.Client(
                    add: { list in
                        try write { db in
                            try List<Reminder>.Record.insert { List<Reminder>.Record(list) }.execute(db)
                            try List<Reminder>.Record.placeLast(list.id).execute(db)
                        }
                    },
                    update: { list in
                        try write { db in
                            guard try List<Reminder>.Record.find(list.id).fetchCount(db) > 0 else { return false }
                            try List<Reminder>.Record.save(List<Reminder>.Record.Draft(List<Reminder>.Record(list))).execute(db)
                            return true
                        }
                    },
                    delete: { id, replacement in
                        try write { db in try List<Reminder>.Record.delete(id, replacement: replacement, in: db) }
                    },
                    reorder: { ids in
                        try write { db in try List<Reminder>.Record.reorder(ids).execute(db) }
                    }
                )
            ),
            tags: Tags(
                client: Tags.Client(
                    add: { title in try write { db in try Tag<Reminder>.Record.add(title, in: db) } },
                    rename: { id, title in try write { db in try Tag<Reminder>.Record.rename(id, to: title, in: db) } },
                    delete: { id in try write { db in try Tag<Reminder>.Record.delete(id).execute(db) } },
                    suggest: { request in try read(request.fetch) }
                )
            ),
            preferences: Preferences(
                client: Preferences.Client(
                    ordering: { ordering, filter in try write { db in try Preference.Record.set(ordering: ordering, for: filter).execute(db) } },
                    toggleShowCompleted: { filter in try write { db in try Preference.Record.toggleShowCompleted(for: filter).execute(db) } }
                )
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
