import GRDB
public import Reminders
public import SQLiteData

// Observing a read request is tracking its query: the value now, then again after every write it depends on.
extension Reminders.Observe.Summary.Request {
    public func stream(in database: any DatabaseReader) -> AsyncThrowingStream<Reminders.Summary, any Swift.Error> {
        Reminders.Observe.stream(in: database, summary.fetch)
    }
}

extension Reminders.Observe.Page.Request {
    public func stream(in database: any DatabaseReader) -> AsyncThrowingStream<Reminders.Page, any Swift.Error> {
        Reminders.Observe.stream(in: database, page.fetch)
    }
}

extension Reminders.Observe {
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
