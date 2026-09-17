public import Reminder

extension Reminders {
    // A search result's text with the matched parts marked: the title and the tag titles whole, the
    // notes as a fragment around a match.
    public struct Highlight: Hashable, Sendable {
        public static let open = "\u{E000}"
        public static let close = "\u{E001}"

        public var title: String
        public var notes: String
        public var tags: String

        public init(title: String, notes: String, tags: String) {
            self.title = title
            self.notes = notes
            self.tags = tags
        }
    }
}
