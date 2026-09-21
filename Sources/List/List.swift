public import Foundation
public import Interface_Macro
public import Tagged

@Memberwise
@Draft(excluding: "id")
public struct List<Element>: Identifiable, Hashable, Sendable {
    public var id: Tagged<List, UUID>
    public var title: String = ""
}

extension List.Draft {
    public var isBlank: Bool { title.allSatisfy(\.isWhitespace) }
}

extension List {
    public static func `default`(id: ID) -> Self { Self(id: id, title: "Personal") }
}

extension List.Draft: Hashable, Sendable {}
