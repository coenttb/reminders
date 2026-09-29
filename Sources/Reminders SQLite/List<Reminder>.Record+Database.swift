import Dependencies
import Foundation
public import GRDB
public import List
public import Reminder
public import Reminders_SQL
import RFC_4122
import SQL
import SQLite
import Tagged

extension List<Reminder>.Record {
    // There is always a list to put a reminder in; its identity is storage's to mint.
    public static func installDefault(in db: Database) throws {
        guard try List<Reminder>.Record.all.fetchCount(db) == 0 else { return }
        @Dependency(\.uuid) var uuid
        try List<Reminder>.Record.insert { List<Reminder>.Record(.default(id: List<Reminder>.ID(RFC_4122.UUID(bytes: uuid().uuid)))) }.execute(db)
    }
}
