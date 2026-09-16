public import Models
import Tagged

extension Tag.Picker {
    public struct Actions {
        public var add: (String) -> Void
        public var rename: (Tag.ID, String) -> Void
        public var delete: (Tag.ID) -> Void

        public init(add: @escaping (String) -> Void, rename: @escaping (Tag.ID, String) -> Void, delete: @escaping (Tag.ID) -> Void) {
            self.add = add
            self.rename = rename
            self.delete = delete
        }
    }
}
