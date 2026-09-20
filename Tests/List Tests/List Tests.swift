import Foundation
import List
import Tagged
import Testing

@Suite struct `List values` {
    @Test func `a list with only whitespace in its title is blank`() {
        let list = List<Int>(id: List<Int>.ID(UUID()), title: "  ")
        #expect(list.draft.isBlank)
        #expect(!List<Int>.default(id: list.id).draft.isBlank)
    }
}
