import Foundation
import Models
import Reminder
import Reminders
import Tagged
import Testing

// The interface is a value built from closures and called as methods, with the labels of the declaration.
@Suite struct `Reminders call sites` {
    let list = Models.List<Reminder>.ID(UUID(uuidString: "00000000-0000-0000-0000-000000000000")!)
    let reminder: Reminder

    init() {
        reminder = Reminder(id: Reminder.ID(UUID(uuidString: "00000000-0000-0000-0000-000000000001")!), list: list, title: "Milk", created: Date(timeIntervalSince1970: 0))
    }

    func reminders() -> Reminders {
        Reminders(
            create: .init { _ in },
            read: .init(
                { _ in Reminders.Summary(lists: [.init(list: .init(id: list, title: "Personal"), count: 1)]) },
                id: { request in
                    guard request.id == reminder.id else { throw Reminders.Read.Error.notFound }
                    return reminder
                },
                page: { request in Reminders.Page(rows: request.filter == .list(list) || request.filter == .all ? [reminder] : []) }
            ),
            update: .init { _ in },
            delete: .init { _ in },
            lists: .init(create: { _ in }, delete: { _ in })
        )
    }

    @Test func `reads are called with the declared labels`() throws {
        let reminders = reminders()
        #expect(try reminders.read().lists.map(\.count) == [1])
        #expect(try reminders.read(reminder.id) == reminder)
        #expect(try reminders.read(page: .list(list)).rows == [reminder])
        #expect(try reminders.read(page: .list(Models.List<Reminder>.ID(UUID()))).rows.isEmpty)
        #expect(throws: Reminders.Read.Error.notFound) { try reminders.read(Reminder.ID(UUID())) }
    }
}
