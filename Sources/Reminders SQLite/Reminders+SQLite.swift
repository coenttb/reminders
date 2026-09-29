import Dependencies
import Foundation
public import GRDB
import List
import Reminder
public import Reminders
import Reminders_SQL
import RFC_4122
import SQL
import SQLite
import Tagged
import Time
import Time_Foundation_Integration

extension Reminders {
    // The domain over one SQLite database: reads on the caller's thread, each write one transaction.
    public static func sqlite(_ database: any DatabaseWriter) -> Reminders {
        Self(
            create: .init { request in
                @Dependency(\.uuid) var uuid
                @Dependency(\.date.now) var now
                let reminder = Reminder(
                    id: Reminder.ID(RFC_4122.UUID(bytes: uuid().uuid)),
                    request.draft,
                    created: try Time.Instant(now)
                )
                try await database.write { db in
                    try Reminder.Record.insert { Reminder.Record.Draft(reminder) }.execute(db)
                    try Reminder.Record.find(reminder.id)
                        .update { $0.position = Reminder.Record.select { ($0.position.max() ?? -1) + 1 } }
                        .execute(db)
                }
                return reminder
            },
            read: .init(
                { request in request.stream(in: database) },
                id: { request in
                    try database.read { db in
                        guard let record = try Reminder.Record.find(request.id).fetchOne(db) else { throw Read.Error.notFound }
                        return Reminder(record)
                    }
                },
                page: .init { request in request.stream(in: database) }
            ),
            update: .init(
                { request in
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
                complete: .init { request in
                    try await database.write { db in
                        guard try Reminder.Record.find(request.id).fetchCount(db) > 0 else { throw Update.Error.notFound }
                        try Reminder.Record.find(request.id).update { $0.completed = request.completed }.execute(db)
                    }
                }
            ),
            delete: .init { request in
                try await database.write { db in try Reminder.Record.find(request.id).delete().execute(db) }
            },
            lists: .init(
                create: .init { request in
                    @Dependency(\.uuid) var uuid
                    let list = List<Reminder>(id: List<Reminder>.ID(RFC_4122.UUID(bytes: uuid().uuid)), request.draft)
                    try await database.write { db in
                        try List<Reminder>.Record.insert { List<Reminder>.Record(list) }.execute(db)
                        try List<Reminder>.Record.find(list.id)
                            .update { $0.position = List<Reminder>.Record.select { ($0.position.max() ?? -1) + 1 } }
                            .execute(db)
                    }
                    return list
                },
                update: .init { request in
                    try await database.write { db in
                        try List<Reminder>.Record.find(request.list.id).update { $0.title = request.list.title }.execute(db)
                    }
                },
                delete: .init { request in
                    try await database.write { db in
                        try List<Reminder>.Record.find(request.id).delete().execute(db)
                        try List<Reminder>.Record.installDefault(in: db)
                    }
                }
            )
        )
    }
}
