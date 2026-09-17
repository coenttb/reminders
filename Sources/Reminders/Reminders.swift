public struct Reminders: Sendable {
    public var create: Create
    public var retrieve: Retrieve
    public var delete: Delete
    public var reorder: Reorder
    public var list: List
    public var start: Start
    public var update: Update
    public var toggle: Toggle
    public var deleteCompleted: DeleteCompleted
    
    public var overview: Overview
    public var lists: Lists
    public var tags: Tags
    public var preferences: Preferences

    public init(
        list: List,
        retrieve: Retrieve,
        start: Start,
        create: Create,
        update: Update,
        toggle: Toggle,
        delete: Delete,
        reorder: Reorder,
        deleteCompleted: DeleteCompleted,
        overview: Overview,
        lists: Lists,
        tags: Tags,
        preferences: Preferences
    ) {
        self.list = list
        self.retrieve = retrieve
        self.start = start
        self.create = create
        self.update = update
        self.toggle = toggle
        self.delete = delete
        self.reorder = reorder
        self.deleteCompleted = deleteCompleted
        self.overview = overview
        self.lists = lists
        self.tags = tags
        self.preferences = preferences
    }
}
