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
            create: .init { request in
                try await database.write { db in
                    try Reminder.Record.insert { Reminder.Record.Draft(request.reminder) }.execute(db)
                    try Reminder.Record.find(request.reminder.id)
                        .update { $0.position = Reminder.Record.select { ($0.position.max() ?? -1) + 1 } }
                        .execute(db)
                }
            },
            read: .init(
                { request in try database.read(request.fetch) },
                id: { request in
                    try database.read { db in
                        guard let record = try Reminder.Record.find(request.id).fetchOne(db) else { throw Read.Error.notFound }
                        return Reminder(record)
                    }
                },
                page: { request in try database.read(request.fetch) }
            ),
            observe: .init(
                summary: { request in request.stream(in: database) },
                page: { request in request.stream(in: database) }
            ),
            update: .init { request in
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
            delete: .init { request in
                try await database.write { db in try Reminder.Record.find(request.id).delete().execute(db) }
            },
            lists: .init(
                create: { request in
                    try await database.write { db in
                        try Models.List<Reminder>.Record.insert { Models.List<Reminder>.Record(request.list) }.execute(db)
                        try Models.List<Reminder>.Record.find(request.list.id)
                            .update { $0.position = Models.List<Reminder>.Record.select { ($0.position.max() ?? -1) + 1 } }
                            .execute(db)
                    }
                },
                delete: { request in
                    try await database.write { db in
                        try Models.List<Reminder>.Record.find(request.id).delete().execute(db)
                        try Models.List<Reminder>.Record.installDefault(request.replacement, in: db)
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
