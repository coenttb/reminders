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
    // A list before it has an identity: what `create` is called with; storage mints the id.
    public struct Draft: Hashable, Sendable {
        public var title: String

        public init(title: String = "") {
            self.title = title
        }

        public var isBlank: Bool { title.allSatisfy(\.isWhitespace) }
    }

    public init(id: ID, _ draft: Draft) {
        self.init(id: id, title: draft.title)
    }

    public var draft: Draft { Draft(title: title) }

    public static func `default`(id: ID) -> Self {
        List(id: id, title: "Personal")
    }

    public var isBlank: Bool { title.allSatisfy(\.isWhitespace) }
}
