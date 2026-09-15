public import Tagged

/// A tag is its title; reminders refer to tags by it.
public struct Tag: Identifiable, Hashable, Sendable {

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
    public var id: Tagged<Tag, String> { ID(title) }
}

extension Tag {
    /// How a tag is shown wherever it is named: its title behind a hash.
    public static func hashtag(_ id: ID) -> String { "#\(id.rawValue)" }

    public var hashtag: String { Self.hashtag(id) }
}
