public struct Reminders: Sendable {
    public var overview: Overview
    public var listing: Listing
    public var editor: Editor
    public var lists: Lists
    public var tags: Tags
    public var preferences: Preferences

    public init(
        overview: Overview,
        listing: Listing,
        editor: Editor,
        lists: Lists,
        tags: Tags,
        preferences: Preferences
    ) {
        self.overview = overview
        self.listing = listing
        self.editor = editor
        self.lists = lists
        self.tags = tags
        self.preferences = preferences
    }
}
