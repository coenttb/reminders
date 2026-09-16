public import Reminders

extension Reminder {
    /// How many rows of a screen's query are read: a screen reads its first rows and widens as
    /// the user nears the end, so the store never holds more than the user has scrolled to.
    /// A window belongs to a key (the filter, the search); another key starts at the first step.
    public struct Window<Key: Hashable & Sendable>: Hashable, Sendable {
        public var key: Key?
        /// Rows read for `key`; nil reads them all.
        public var rows: Int?

        public static var step: Int { 300 }
        /// A row this many from the end asks for the next step.
        public static var margin: Int { 60 }

        public init(key: Key? = nil, rows: Int? = Self.step) {
            self.key = key
            self.rows = rows
        }

        /// The limit for a key: its own when the window is for it, the first step otherwise.
        public func limit(for key: Key) -> Int? {
            self.key == key ? rows : Self.step
        }

        /// One step wider, while there is more to show.
        public mutating func widen(for key: Key, shown: Int, total: Int) {
            guard shown < total, let limit = limit(for: key) else { return }
            self.key = key
            rows = limit + Self.step
        }

        /// Wider by a few rows, for rows added inside the window.
        public mutating func extend(for key: Key, by count: Int) {
            guard let limit = limit(for: key) else { return }
            self.key = key
            rows = limit + count
        }

        /// Everything, for when the user is taken to the end.
        public mutating func open(for key: Key) {
            self.key = key
            rows = nil
        }

        /// Whether a row at an index is close enough to the end to ask for more.
        public static func nearsEnd(_ index: Int, of shown: Int, total: Int) -> Bool {
            shown < total && index >= shown - margin
        }
    }
}
