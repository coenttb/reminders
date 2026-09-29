public import Interface_Macro
public import RFC_4122
public import Tagged

@Memberwise
@Draft(excluding: "id")
public struct List<Element>: Identifiable, Hashable, Sendable {
    public var id: Tagged<List, RFC_4122.UUID>
    public var title: String = ""
}

extension List.Draft {
    public var isBlank: Bool { title.allSatisfy(\.isWhitespace) }
}

extension List {
    public static func `default`(id: ID) -> Self { Self(id: id, title: "Personal") }
}

extension List.Draft: Hashable, Sendable {}
