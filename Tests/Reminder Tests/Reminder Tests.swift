import List
import Reminder
import RFC_4122
import Tagged
import Testing
import Time

@Suite struct `Reminder values` {
    @Test func `a new reminder is blank and open`() throws {
        let reminder = Reminder(
            id: Reminder.ID(try RFC_4122.UUID("00000000-0000-0000-0000-000000000001")),
            list: List<Reminder>.ID(try RFC_4122.UUID("00000000-0000-0000-0000-000000000002")),
            created: Time.Instant(secondsSinceUnixEpoch: 0)
        )
        #expect(reminder.draft.isBlank)
        #expect(!reminder.completed)
    }
}


@Test func draftAssignmentPreservesIdentityAndObeysLensLaws() throws {
    let original = Reminder(
        id: .init(try RFC_4122.UUID("00000000-0000-0000-0000-000000000001")),
        list: .init(try RFC_4122.UUID("00000000-0000-0000-0000-000000000002")),
        title: "Before", created: Time.Instant(secondsSinceUnixEpoch: 123)
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
