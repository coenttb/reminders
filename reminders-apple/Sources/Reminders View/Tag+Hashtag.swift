public import Models
import Tagged

extension Tag {
    public static func hashtag(_ tag: Self) -> String { "#\(tag.rawValue)" }

    public var hashtag: String { Self.hashtag(self) }
}
