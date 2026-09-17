extension Reminders.Tags {
    public enum Error: Swift.Error, Hashable, Sendable {
        case blank
        case notFound
    }
}
