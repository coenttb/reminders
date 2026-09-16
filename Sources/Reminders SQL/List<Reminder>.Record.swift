public import Organizing
public import Reminders
public import StructuredQueries
public import Tagged

extension List<Reminder>  {
    @Table("lists")
    public struct Record: Identifiable, Sendable {
        public let id: List<Reminder>.ID
        public var title: String
        public var color: Color.Hex
        public var position: Int

        init(id: List<Reminder>.ID, title: String, color: Color.Hex, position: Int) {
            self.id = id
            self.title = title
            self.color = color
            self.position = position
        }
    }
}

extension List<Reminder>.Record {
    public init(_ list: List<Reminder>) {
        self.init(id: list.id, title: list.title, color: Color.Hex(list.color), position: list.position)
    }
}

extension List<Reminder>.Record {
    public static func placeLast(_ id: List<Reminder>.ID) -> UpdateOf<List<Reminder>.Record> {
        List<Reminder>.Record.find(id).update { $0.position = List<Reminder>.Record.select { ($0.position.max() ?? -1) + 1 } }
    }

    public static func changes(from original: List<Reminder>, to draft: List<Reminder>) -> UpdateOf<List<Reminder>.Record>? {
        guard draft != original else { return nil }
        return List<Reminder>.Record.find(original.id).update { row in
            if draft.title != original.title { row.title = draft.title }
            if draft.color != original.color { row.color = Color.Hex(draft.color) }
            if draft.position != original.position { row.position = draft.position }
        }
    }

    public static func reorder(_ ids: [List<Reminder>.ID]) -> UpdateOf<List<Reminder>.Record> {
        List<Reminder>.Record.where { $0.id.in(ids) }.update { row in
            let places = Array(ids.enumerated())
            guard let first = places.first else { return }
            row.position = places.dropFirst()
                .reduce(Case(row.id).when(first.element, then: first.offset)) { cases, place in
                    cases.when(place.element, then: place.offset)
                }
                .else(row.position)
        }
    }
}
