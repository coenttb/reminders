public import Tagged

public struct Tag<Element>: Identifiable, Hashable, Sendable {
    public var title: String

    public init(title: String) {
        self.title = title
    }

    public init(_ id: ID) {
        title = id.rawValue
    }
}

extension Tag {
    public var id: Tagged<Tag, String> { ID(title) }
}
