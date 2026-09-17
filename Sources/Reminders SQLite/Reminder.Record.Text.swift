import Foundation
public import Reminder
public import Reminders_SQL
public import SQLiteData

extension Reminder.Record.Text {
    // The terms as one query: each term a phrase matched at the start of a word, all of them required.
    // The user's text is quoted so it can never be read as query syntax.
    public static func pattern(_ terms: [String]) -> String? {
        let phrases = terms.compactMap { term -> String? in
            let words = term.split(whereSeparator: \.isWhitespace).joined(separator: " ")
            return words.isEmpty ? nil : "\"" + words.replacingOccurrences(of: "\"", with: "\"\"") + "\"*"
        }
        return phrases.isEmpty ? nil : phrases.joined(separator: " AND ")
    }
}

extension Reminder.Record {
    // The full-text index of a reminder: its title, its notes, and its tag titles, kept in step by
    // triggers and addressed by the reminder's rowid.
    @Table("reminderTexts")
    public struct Text: FTS5, Sendable {
        public let rowid: Int
        public var title: String
        public var notes: String
        public var tags: String
    }
}

extension Reminder.Record {
    // A search hit: the row and its text with the matches marked.
    @Selection
    public struct Hit: Sendable {
        public let reminder: Reminder.Record
        @Column(as: [String].JSONRepresentation.self)
        public let tags: [String]
        public let title: String
        public let notes: String
        public let tagLine: String
    }
}
