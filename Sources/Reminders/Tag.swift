public import Tagged

/// A tag is its title; reminders refer to tags by it.
public struct Tag: Identifiable, Hashable, Sendable {
    public typealias ID = Tagged<Tag, String>

    public var title: String

    public init(title: String) {
        self.title = title
    }

    /// The tag an identifier names.
    public init(_ id: ID) {
        title = id.rawValue
    }
}

extension Tag {
    public var id: ID { ID(title) }
}
