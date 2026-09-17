public import Foundation
public import StructuredQueries

extension SortOrder {
    public struct Representation: QueryRepresentable, QueryBindable, Hashable, Sendable {
        public var queryOutput: SortOrder

        public init(queryOutput: SortOrder) {
            self.queryOutput = queryOutput
        }

        public var queryBinding: QueryBinding {
            (queryOutput == .forward ? "forward" : "reverse").queryBinding
        }

        public init(decoder: inout some QueryDecoder) throws {
            switch try String(decoder: &decoder) {
            case "forward": self.init(queryOutput: .forward)
            case "reverse": self.init(queryOutput: .reverse)
            case let name: throw Unknown(name: name)
            }
        }

        public struct Unknown: Error {
            public let name: String
        }
    }
}
