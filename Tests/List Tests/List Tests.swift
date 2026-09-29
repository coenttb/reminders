import List
import RFC_4122
import Tagged
import Testing

@Suite struct `List values` {
    @Test func `a list with only whitespace in its title is blank`() throws {
        let list = List<Int>(id: List<Int>.ID(try RFC_4122.UUID("00000000-0000-0000-0000-000000000001")), title: "  ")
        #expect(list.draft.isBlank)
        #expect(!List<Int>.default(id: list.id).draft.isBlank)
    }
}
