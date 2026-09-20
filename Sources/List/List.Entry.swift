public import Interface_Macro
public import Tagged

extension List {
    // A list with the number of open reminders it holds.
    @Memberwise
    public struct Entry: Identifiable, Hashable, Sendable {
        public var list: List
        public var count: Int

        public var id: List.ID { list.id }
    }
}
