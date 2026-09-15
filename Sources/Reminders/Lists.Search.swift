public import Foundation
public import Tagged

extension Lists {
    /// What the user typed into search: free text plus committed tokens.
    public struct Search: Hashable, Sendable {
        public var text: String
        public var tokens: [Token]
        public var showCompleted: Bool

        public init(text: String = "", tokens: [Token] = [], showCompleted: Bool = false) {
            self.text = text
            self.tokens = tokens
            self.showCompleted = showCompleted
        }
    }
}

extension Lists.Search {
    /// A committed search term: free text the reminder must contain, or a tag it must carry.
    public enum Token: Hashable, Identifiable, Sendable {
        case near(String)
        case tag(Tag.ID)

        public var id: Self { self }
    }

    public var isActive: Bool { !text.isEmpty || !tokens.isEmpty }

    /// Typed `#` starts tag completion.
    public var tagPrefix: String? {
        text.hasPrefix("#") ? String(text.dropFirst()) : nil
    }

    /// Submitting the field commits the trimmed text as a near token; a tag prefix is
    /// left for the suggestions.
    public mutating func commitText() {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard tagPrefix == nil, !trimmed.isEmpty else { return }
        tokens.append(.near(trimmed))
        text = ""
    }

    public mutating func add(tag: Tag.ID) {
        tokens.append(.tag(tag))
        text = ""
    }
}

extension Lists {
    /// Every reminder the search matches, completed ones included, open ones first and by due
    /// date; one in its grace period keeps its place among the open ones, as in a detail.
    public func matches(_ search: Lists.Search) -> [Reminder] {
        guard search.isActive else { return [] }
        // A tag prefix alone offers suggestions, not the whole database.
        guard search.tagPrefix == nil || !search.tokens.isEmpty else { return [] }
        let text = search.tagPrefix == nil ? search.text : ""
        return reminders.filter { reminder in
            guard text.isEmpty || reminder.matches(text) else { return false }
            return search.tokens.allSatisfy { token in
                switch token {
                case let .near(text): reminder.matches(text)
                case let .tag(tag): reminder.tags.contains(tag)
                }
            }
        }
        .sorted { lhs, rhs in
            let (l, r) = (lhs.status == .completed, rhs.status == .completed)
            if l != r { return !l }
            return Lists.precedes(lhs, rhs, by: .dueDate)
        }
    }

    /// Tags completing the typed prefix, excluding ones already tokenized.
    public func tagSuggestions(for search: Lists.Search) -> [Tag] {
        guard let prefix = search.tagPrefix else { return [] }
        let taken = Set(search.tokens.compactMap { if case let .tag(tag) = $0 { tag } else { nil } })
        return tags.filter { $0.title.lowercased().hasPrefix(prefix.lowercased()) && !taken.contains($0.id) }
            .sorted { $0.title < $1.title }
    }

    /// Deletes completed reminders the search matches, optionally only those due more than
    /// some months ago. A reminder still in its grace period is kept, so the tap can be undone.
    public mutating func deleteCompleted(matching search: Lists.Search, olderThanMonths months: Int?, at now: Date) {
        let cutoff = months.map { Calendar.current.date(byAdding: .month, value: -$0, to: now) ?? now }
        let doomed = Set(matches(search).filter { reminder in
            guard reminder.status == .completed else { return false }
            guard let cutoff else { return true }
            guard let due = reminder.due else { return false }
            return due < cutoff
        }.map(\.id))
        reminders.removeAll { doomed.contains($0.id) }
    }
}
