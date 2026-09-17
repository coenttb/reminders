import Dependencies
import Foundation
public import Models
public import Reminder
public import Reminders
public import SQLiteData

// The read requests are the fetch keys: a feature observes a domain address and SQLite resolves it.
extension Reminders.Read.Today.Request: FetchKeyRequest {
    public func fetch(_ db: Database) throws -> Reminders.Summary {
        @Dependency(\.calendar) var calendar
        return try Reminders.Summary.Query(self, calendar: calendar).fetch(db)
    }
}

extension Reminders.Read.Page.Request: FetchKeyRequest {
    public func fetch(_ db: Database) throws -> Reminders.Page {
        @Dependency(\.calendar) var calendar
        return try Reminders.Page.Query(self, calendar: calendar).fetch(db)
    }
}

extension Reminders.Read.Search.Request: FetchKeyRequest {
    public func fetch(_ db: Database) throws -> Reminders.Page {
        @Dependency(\.calendar) var calendar
        return try Reminders.Page.Query(self, calendar: calendar).fetch(db)
    }
}

extension Reminders.Read.Preference.Request: FetchKeyRequest {
    public func fetch(_ db: Database) throws -> Reminders.Preference {
        try Reminders.Preference.Query(self).fetch(db)
    }
}

extension Reminders.Tags.Suggest.Request: FetchKeyRequest {
    public func fetch(_ db: Database) throws -> [Tag<Reminder>] {
        try Reminders.Tags.Query(self).fetch(db)
    }
}
