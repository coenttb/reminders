public import Organizing
public import Reminder
public import Reminders
public import StructuredQueries
public import Tagged

extension List<Reminder> {
    @Table("lists")
    public struct Record: Identifiable, Hashable, Sendable {
        public let id: List<Reminder>.ID
        public var title: String = ""
        public var color: Color.Hex = Color.Hex(Color.default)
        public var position: Int = 0

        public init(id: List<Reminder>.ID, title: String = "", color: Color.Hex = Color.Hex(Color.default), position: Int = 0) {
            self.id = id
            self.title = title
            self.color = color
            self.position = position
        }
    }
}

extension List<Reminder>.Record.Draft: Hashable, Sendable {}

extension List<Reminder>.Record {
    public init(_ list: List<Reminder>) {
        self.init(id: list.id, title: list.title, color: Color.Hex(list.color), position: list.position)
    }
}

extension List<Reminder>.Record {
    public static func placeLast(_ id: List<Reminder>.ID) -> UpdateOf<List<Reminder>.Record> {
        List<Reminder>.Record.find(id).update { $0.position = List<Reminder>.Record.select { ($0.position.max() ?? -1) + 1 } }
    }

    public static func save(_ draft: Draft) -> InsertOf<List<Reminder>.Record> {
        List<Reminder>.Record.insert {
            draft
        } onConflict: {
            $0.id
        } doUpdate: { row, excluded in
            row.title = excluded.title
            row.color = excluded.color
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
