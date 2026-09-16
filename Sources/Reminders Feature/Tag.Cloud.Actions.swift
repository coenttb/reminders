public import Models
import Tagged

extension Tag.Cloud {
    public struct Actions {
        public var open: ([Tag.ID]) -> Void
        public var delete: (Tag.ID) -> Void

        public init(open: @escaping ([Tag.ID]) -> Void, delete: @escaping (Tag.ID) -> Void) {
            self.open = open
            self.delete = delete
        }
    }
}
