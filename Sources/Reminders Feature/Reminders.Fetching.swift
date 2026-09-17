public import Reminders
public import SQLiteData

extension Reminders {
    // A fetch that may have no address yet; `nil` clears the value.
    public struct Fetching<Request: FetchKeyRequest>: FetchKeyRequest {
        public var request: Request?

        public init(_ request: Request?) {
            self.request = request
        }

        public func fetch(_ db: Database) throws -> Request.Value? {
            try request?.fetch(db)
        }
    }
}
