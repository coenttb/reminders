public struct Reminders: Sendable {
    public var overview: Overview
    public var search: Search
    public var detail: Filter.Detail
    public var pending: Pending
    public var editor: Editor
    public var lists: Lists
    public var tags: Tags
    public var restoration: Restoration

    public init(
        overview: Overview,
        search: Search,
        detail: Filter.Detail,
        pending: Pending,
        editor: Editor,
        lists: Lists,
        tags: Tags,
        restoration: Restoration
    ) {
        self.overview = overview
        self.search = search
        self.detail = detail
        self.pending = pending
        self.editor = editor
        self.lists = lists
        self.tags = tags
        self.restoration = restoration
    }
}
