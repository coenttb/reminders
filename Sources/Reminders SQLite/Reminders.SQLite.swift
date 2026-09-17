public import Reminders

extension Reminders {
    public enum SQLite {
        public enum Error: Swift.Error, Hashable, Sendable {
            case notFound
            case blank
        }
    }
}
