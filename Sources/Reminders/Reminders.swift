public struct Reminders: Sendable {
    public var overview: Overview
    public var search: Search
    public var detail: Filter.Detail
    public var pending: Pending

    public init(overview: Overview, search: Search, detail: Filter.Detail, pending: Pending) {
        self.overview = overview
        self.search = search
        self.detail = detail
        self.pending = pending
    }
}
