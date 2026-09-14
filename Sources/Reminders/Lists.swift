public import Foundation
public import Tagged

/// Everything the Reminders app owns: the lists, their reminders, the known tags,
/// the per-detail preferences, and which detail is open. Pure value; the rules
/// that filter, order, search, and count live here so every platform shares them.
public struct Lists: Equatable, Sendable {
    public var lists: [Reminder.List]
    public var reminders: [Reminder]
    public var tags: Set<Tag>
    public var preferences: [Detail.ID: Detail.Preference]
    public var detail: Detail?

    public init(
        lists: [Reminder.List],
        reminders: [Reminder] = [],
        tags: Set<Tag> = [],
        preferences: [Detail.ID: Detail.Preference] = [:],
        detail: Detail? = nil
    ) {
        self.lists = lists
        self.reminders = reminders
        self.tags = tags
        self.preferences = preferences
        self.detail = detail
    }
}

extension Lists {
    /// Lists in the user's order.
    public var orderedLists: [Reminder.List] { lists.sorted { $0.position < $1.position } }

    /// Tags at least one reminder carries, alphabetically.
    public var usedTags: [Tag] {
        let used = Set(reminders.flatMap(\.tags))
        return tags.filter { used.contains($0.id) }.sorted { $0.title < $1.title }
    }

    /// Tags alphabetically, the most used first.
    public var rankedTags: [Tag] {
        let counts = reminders.flatMap(\.tags).reduce(into: [Tag.ID: Int]()) { $0[$1, default: 0] += 1 }
        return tags.sorted { lhs, rhs in
            let (l, r) = (counts[lhs.id] ?? 0, counts[rhs.id] ?? 0)
            return l == r ? lhs.title < rhs.title : l > r
        }
    }

    public func list(_ id: Reminder.List.ID) -> Reminder.List? { lists.first { $0.id == id } }

    public func reminder(_ id: Reminder.ID) -> Reminder? { reminders.first { $0.id == id } }

    /// Incomplete reminders in a list.
    public func count(in list: Reminder.List.ID) -> Int {
        reminders.filter { $0.list == list && !$0.completed }.count
    }

    /// Reminders still in their completion grace period.
    public var completing: Set<Reminder.ID> { Set(reminders.filter { $0.status == .completing }.map(\.id)) }

    public var isEmpty: Bool { lists.isEmpty }
}

extension Lists {
    public mutating func upsert(_ reminder: Reminder) {
        var reminder = reminder
        for tag in reminder.tags { tags.insert(Tag(tag)) }
        if let index = reminders.firstIndex(where: { $0.id == reminder.id }) {
            reminders[index] = reminder
        } else {
            reminder.position = (reminders.map(\.position).max() ?? -1) + 1
            reminders.append(reminder)
        }
    }

    public mutating func upsert(_ list: Reminder.List) {
        var list = list
        if let index = lists.firstIndex(where: { $0.id == list.id }) {
            lists[index] = list
        } else {
            list.position = (lists.map(\.position).max() ?? -1) + 1
            lists.append(list)
        }
    }

    /// Removes the list and its reminders; the caller keeps the default-list invariant with `isEmpty`.
    public mutating func delete(list id: Reminder.List.ID) {
        lists.removeAll { $0.id == id }
        reminders.removeAll { $0.list == id }
        if case let .list(open) = detail, open == id { detail = nil }
    }

    public mutating func delete(reminder id: Reminder.ID) {
        reminders.removeAll { $0.id == id }
    }

    /// Removes the tag everywhere it is used.
    public mutating func delete(tag id: Tag.ID) {
        tags.remove(Tag(id))
        for index in reminders.indices { reminders[index].tags.remove(id) }
        if case let .tags(open) = detail { detail = open == [id] ? nil : .tags(open.filter { $0 != id }) }
    }

    /// Adds a tag nothing uses yet; adding an existing title is a no-op.
    public mutating func add(tag title: String) {
        guard !title.isEmpty, !tags.contains(where: { $0.title.caseInsensitiveCompare(title) == .orderedSame }) else { return }
        tags.insert(Tag(title: title))
    }

    public mutating func rename(tag id: Tag.ID, to title: String) {
        guard !title.isEmpty, tags.remove(Tag(id)) != nil else { return }
        tags.insert(Tag(title: title))
        for reminderIndex in reminders.indices where reminders[reminderIndex].tags.remove(id) != nil {
            reminders[reminderIndex].tags.insert(Tag.ID(title))
        }
    }

    public mutating func toggle(_ id: Reminder.ID) {
        guard let index = reminders.firstIndex(where: { $0.id == id }) else { return }
        reminders[index].toggle()
    }

    /// Every reminder in its grace period is now completed.
    public mutating func completeCompleting() {
        for index in reminders.indices { reminders[index].complete() }
    }

    public mutating func flag(_ id: Reminder.ID) {
        guard let index = reminders.firstIndex(where: { $0.id == id }) else { return }
        reminders[index].flagged.toggle()
    }

    /// Reorders the lists as the user dragged them.
    public mutating func move(lists source: IndexSet, to destination: Int) {
        var ordered = orderedLists
        ordered.move(offsets: source, to: destination)
        for (position, list) in ordered.enumerated() {
            if let index = lists.firstIndex(where: { $0.id == list.id }) { lists[index].position = position }
        }
    }

    /// Reorders the reminders shown in a detail as the user dragged them, and switches that detail to manual ordering.
    public mutating func move(reminders source: IndexSet, to destination: Int, in detail: Detail, at now: Date) {
        var shown = reminders(in: detail, at: now)
        shown.move(offsets: source, to: destination)
        var positions = shown.map(\.position).sorted()
        for reminder in shown {
            if let index = reminders.firstIndex(where: { $0.id == reminder.id }) { reminders[index].position = positions.removeFirst() }
        }
        preferences[detail.id, default: detail.defaultPreference].ordering = .manual
    }
}
