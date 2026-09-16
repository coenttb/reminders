extension Tag {
    public struct Entry: Identifiable, Hashable, Sendable {
        public var tag: Tag
        public var count: Int

        public var id: Tag { tag }

        public init(tag: Tag, count: Int) {
            self.tag = tag
            self.count = count
        }
    }
}
