public import Foundation
public import Organizing

extension List {
    public struct Draft: Hashable, Sendable {
        public var list: List
        public let original: List
        public let isNew: Bool
        public let session: UUID

        public init(_ list: List, isNew: Bool, session: UUID) {
            self.list = list
            self.original = list
            self.isNew = isNew
            self.session = session
        }

        public var isDirty: Bool { list != original }
    }
}
