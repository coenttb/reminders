public import Tagged

extension Tag {
    public struct Entry: Identifiable, Hashable, Sendable {
        public var tag: Tag
        public var count: Int

        public var id: Tag.ID { tag.id }

        public init(tag: Tag, count: Int) {
            self.tag = tag
            self.count = count
        }
    }
}
