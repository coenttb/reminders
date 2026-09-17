public import Models
public import Reminder
public import StructuredQueries
public import Tagged

extension Models.List<Reminder> {
    @Table("lists")
    public struct Record: Identifiable, Hashable, Sendable {
        public let id: Models.List<Reminder>.ID
        public var title: String = ""
        public var color: Color.Hex = Color.Hex(Color.default)
        public var position: Int = 0

        public init(id: Models.List<Reminder>.ID, title: String = "", color: Color.Hex = Color.Hex(Color.default), position: Int = 0) {
            self.id = id
            self.title = title
            self.color = color
            self.position = position
        }
    }
}

extension Models.List<Reminder>.Record.Draft: Hashable, Sendable {}

extension Models.List<Reminder>.Record {
    public init(_ list: Models.List<Reminder>, position: Int = 0) {
        self.init(id: list.id, title: list.title, color: Color.Hex(list.color), position: position)
    }
}

extension Models.List<Reminder> {
    public init(_ record: Models.List<Reminder>.Record) {
        self.init(id: record.id, title: record.title, color: Color(record.color))
    }
}

extension Models.List<Reminder>.Entry {
    public init(_ entry: Models.List<Reminder>.Record.Entry) {
        self.init(list: Models.List<Reminder>(entry.list), count: entry.count)
    }
}

extension Models.List<Reminder>.Record {
    public static func placeLast(_ id: Models.List<Reminder>.ID) -> UpdateOf<Models.List<Reminder>.Record> {
        Models.List<Reminder>.Record.find(id).update { $0.position = Models.List<Reminder>.Record.select { ($0.position.max() ?? -1) + 1 } }
    }

    public static func save(_ draft: Draft) -> InsertOf<Models.List<Reminder>.Record> {
        Models.List<Reminder>.Record.insert {
            draft
        } onConflict: {
            $0.id
        } doUpdate: { row, excluded in
            row.title = excluded.title
            row.color = excluded.color
        }
    }

    public static func reorder(_ ids: [Models.List<Reminder>.ID]) -> UpdateOf<Models.List<Reminder>.Record> {
        Models.List<Reminder>.Record.where { $0.id.in(ids) }.update { row in
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
