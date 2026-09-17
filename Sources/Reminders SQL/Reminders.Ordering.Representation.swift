public import Reminders
public import StructuredQueries

extension Reminders.Ordering {
    public struct Representation: QueryRepresentable, QueryBindable, Hashable, Sendable {
        public var queryOutput: Reminders.Ordering

        public init(queryOutput: Reminders.Ordering) {
            self.queryOutput = queryOutput
        }

        public var queryBinding: QueryBinding {
            Self.name(of: queryOutput).queryBinding
        }

        public init(decoder: inout some QueryDecoder) throws {
            let name = try String(decoder: &decoder)
            guard let ordering = Self.ordering(named: name) else { throw Unknown(name: name) }
            self.init(queryOutput: ordering)
        }

        public struct Unknown: Error {
            public let name: String
        }

        static func name(of ordering: Reminders.Ordering) -> String {
            switch ordering {
            case .manual: "manual"
            case .dueDate: "dueDate"
            case .creationDate: "creationDate"
            case .priority: "priority"
            case .title: "title"
            }
        }

        static func ordering(named name: String) -> Reminders.Ordering? {
            Reminders.Ordering.allCases.first { self.name(of: $0) == name }
        }
    }
}
