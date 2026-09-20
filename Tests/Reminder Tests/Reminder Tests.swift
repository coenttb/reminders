import Foundation
import List
import Reminder
import Tagged
import Testing

@Suite struct `Reminder values` {
    @Test func `a new reminder is blank and open`() {
        let reminder = Reminder(id: Reminder.ID(UUID()), list: List<Reminder>.ID(UUID()), created: Date())
        #expect(reminder.draft.isBlank)
        #expect(!reminder.completed)
    }
}


@Test func draftAssignmentPreservesIdentityAndObeysLensLaws() {
    let original = Reminder(
        id: .init(UUID(uuidString: "00000000-0000-0000-0000-000000000001")!),
        list: .init(UUID(uuidString: "00000000-0000-0000-0000-000000000002")!),
        title: "Before", created: Date(timeIntervalSince1970: 123)
    )
    var value = original
    value.draft = original.draft
    #expect(value == original)
    var first = original.draft
    first.title = "After"
    value.draft = first
    #expect(value.draft == first)
    #expect(value.id == original.id && value.created == original.created)
    var second = first
    second.completed = true
    value.draft = second
    var direct = original
    direct.draft = second
    #expect(value == direct)
}
