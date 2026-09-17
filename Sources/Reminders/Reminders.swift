public struct Reminders: Sendable {
    public var create: Create
    public var retrieve: Retrieve
    public var update: Update
    public var delete: Delete
    public var list: List
    public var reorder: Reorder
    public var complete: Complete
    public var reopen: Reopen
    public var deleteCompleted: DeleteCompleted

    public var overview: Overview
    public var lists: Lists
    public var tags: Tags
    public var preferences: Preferences

    public init(
        create: Create,
        retrieve: Retrieve,
        update: Update,
        delete: Delete,
        list: List,
        reorder: Reorder,
        complete: Complete,
        reopen: Reopen,
        deleteCompleted: DeleteCompleted,
        overview: Overview,
        lists: Lists,
        tags: Tags,
        preferences: Preferences
    ) {
        self.create = create
        self.retrieve = retrieve
        self.update = update
        self.delete = delete
        self.list = list
        self.reorder = reorder
        self.complete = complete
        self.reopen = reopen
        self.deleteCompleted = deleteCompleted
        self.overview = overview
        self.lists = lists
        self.tags = tags
        self.preferences = preferences
    }
}
