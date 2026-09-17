extension Reminders {
    public enum Error: Swift.Error, Hashable, Sendable {
        case notFound
        case blank
    }
}
