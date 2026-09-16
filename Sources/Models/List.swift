public import Foundation
public import Tagged

public struct List<Element>: Identifiable, Hashable, Sendable {
    public var id: Tagged<List, UUID>
    public var title: String
    public var color: Color
    public var position: Int

    public init(
        id: ID,
        title: String = "",
        color: Color = .default,
        position: Int = 0
    ) {
        self.id = id
        self.title = title
        self.color = color
        self.position = position
    }
}

extension List {
    public static func `default`(id: ID) -> Self {
        List(id: id, title: "Personal", color: .default)
    }

    public static func isBlank(title: String) -> Bool { title.allSatisfy(\.isWhitespace) }

    public static func isBlank(_ list: Self) -> Bool { isBlank(title: list.title) }

    public var isBlank: Bool { Self.isBlank(self) }
}
