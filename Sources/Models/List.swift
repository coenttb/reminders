public import Foundation
public import Tagged

public struct List<Element>: Identifiable, Hashable, Sendable {
    public var id: Tagged<List, UUID>
    public var title: String

    public init(id: ID, title: String = "") {
        self.id = id
        self.title = title
    }
}

extension List {
    public static func `default`(id: ID) -> Self {
        List(id: id, title: "Personal")
    }

    public var isBlank: Bool { title.allSatisfy(\.isWhitespace) }
}
