public import Dependencies
import Models
import Reminder
public import Reminders
public import Reminders_Dependency
import Reminders_SQL
public import SQLiteData
import Tagged

extension Reminders {
    // The domain over one SQLite database: reads on the caller's thread, each write one transaction.
    public static func sqlite(_ database: any DatabaseWriter) -> Reminders {
        Self(
            create: .init(run: { request in
                @Dependency(\.uuid) var uuid
                @Dependency(\.date.now) var now
                let reminder = Reminder(id: Reminder.ID(uuid()), request.draft, created: now)
                try await database.write { db in
                    try Reminder.Record.insert { Reminder.Record.Draft(reminder) }.execute(db)
                    try Reminder.Record.find(reminder.id)
                        .update { $0.position = Reminder.Record.select { ($0.position.max() ?? -1) + 1 } }
                        .execute(db)
                }
                return reminder
            }),
            read: .init(
                run: { request in request.stream(in: database) },
                id: { request in
                    try database.read { db in
                        guard let record = try Reminder.Record.find(request.id).fetchOne(db) else { throw Read.Error.notFound }
                        return Reminder(record)
                    }
                },
                page: { request in request.stream(in: database) }
            ),
            update: .init(
                run: { request in
                    try await database.write { db in
                        guard try Reminder.Record.find(request.reminder.id).fetchCount(db) > 0 else { throw Update.Error.notFound }
                        try Reminder.Record.find(request.reminder.id).update {
                            $0.listID = request.reminder.list
                            $0.title = request.reminder.title
                            $0.completed = request.reminder.completed
                        }
                        .execute(db)
                    }
                },
                complete: { request in
                    try await database.write { db in
                        guard try Reminder.Record.find(request.id).fetchCount(db) > 0 else { throw Update.Error.notFound }
                        try Reminder.Record.find(request.id).update { $0.completed = request.completed }.execute(db)
                    }
                }
            ),
            delete: .init(run: { request in
                try await database.write { db in try Reminder.Record.find(request.id).delete().execute(db) }
            }),
            lists: .init(
                create: { request in
                    @Dependency(\.uuid) var uuid
                    let list = Models.List<Reminder>(id: Models.List<Reminder>.ID(uuid()), request.draft)
                    try await database.write { db in
                        try Models.List<Reminder>.Record.insert { Models.List<Reminder>.Record(list) }.execute(db)
                        try Models.List<Reminder>.Record.find(list.id)
                            .update { $0.position = Models.List<Reminder>.Record.select { ($0.position.max() ?? -1) + 1 } }
                            .execute(db)
                    }
                    return list
                },
                delete: { request in
                    try await database.write { db in
                        try Models.List<Reminder>.Record.find(request.id).delete().execute(db)
                        try Models.List<Reminder>.Record.installDefault(in: db)
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
