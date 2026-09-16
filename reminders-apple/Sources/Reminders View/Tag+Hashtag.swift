public import Models
public import Tagged

extension Tag {
    public static func hashtag(_ id: ID) -> String { "#\(id.rawValue)" }

    public var hashtag: String { Self.hashtag(id) }
}
