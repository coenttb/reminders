public import Organizing
public import Tagged

extension Tag {
    /// How a tag is shown wherever it is named: its title behind a hash.
    public static func hashtag(_ id: ID) -> String { "#\(id.rawValue)" }

    public var hashtag: String { Self.hashtag(id) }
}
