import GRDB
public import List
public import Reminder
public import Reminders
import Reminders_SQL
public import SQLiteData
import Tagged

// A read request resolved against one database connection; the streamed ones track their query, so the
// value arrives now and again after every write it depends on.
extension Reminders.Read.Run.Input {
    public func fetch(_ db: Database) throws -> Reminders.Read.Value {
        Reminders.Read.Value(
            lists: try List<Reminder>.Record
                .group(by: \.id)
                .order(by: \.position)
                .leftJoin(Reminder.Record.all) { $0.id.eq($1.listID) }
                .select { List<Reminder>.Record.Entry.Columns(list: $0, count: $1.id.count(filter: $1.completed.eq(false))) }
                .fetchAll(db)
                .map(List<Reminder>.Entry.init)
        )
    }

    public func stream(in database: any DatabaseReader) -> AsyncThrowingStream<Reminders.Read.Value, any Swift.Error> {
        Reminders.Read.stream(in: database, fetch)
    }
}

extension Reminders.Read.Page.Run.Input {
    public func fetch(_ db: Database) throws -> Reminders.Read.Page.Value {
        Reminders.Read.Page.Value(
            rows: try Reminder.Record
                .where { $0.belongs(to: filter) }
                .order(by: \.position)
                .fetchAll(db)
                .map(Reminder.init)
        )
    }

    public func stream(in database: any DatabaseReader) -> AsyncThrowingStream<Reminders.Read.Page.Value, any Swift.Error> {
        Reminders.Read.stream(in: database, fetch)
    }
}

extension Reminders.Read {
    static func stream<Value: Sendable>(
        in database: any DatabaseReader,
        _ fetch: @escaping @Sendable (Database) throws -> Value
    ) -> AsyncThrowingStream<Value, any Swift.Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    for try await value in ValueObservation.tracking(fetch).values(in: database) {
                        continuation.yield(value)
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }
}
