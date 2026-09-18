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
            create: .init(run: { _ in }),
            read: .init(
                run: { _ in
                    AsyncThrowingStream {
                        $0.yield(Reminders.Read.Value(lists: [.init(list: .init(id: list, title: "Personal"), count: 1)]))
                        $0.finish()
                    }
                },
                id: { request in
                    guard request.id == reminder.id else { throw Reminders.Read.Error.notFound }
                    return reminder
                },
                page: { request in
                    AsyncThrowingStream {
                        $0.yield(Reminders.Read.Page.Value(rows: request.filter == .list(list) || request.filter == .all ? [reminder] : []))
                        $0.finish()
                    }
                }
            ),
            update: .init(run: { _ in }, complete: { _ in }),
            delete: .init(run: { _ in }),
            lists: .init(create: { _ in }, delete: { _ in })
        )
    }

    // A call is a value: built with the declared labels, compared, and interpreted by the interface.
    @Test func `calls are values the interface interprets`() async throws {
        let reminders = reminders()
        try await reminders(.lists.delete(list))
        try await reminders(.read(page: .all))
        #expect(Reminders.Lists.Call.delete(list) == .delete(list))
        #expect(Reminders.Call.delete(reminder.id) != .delete(Reminder.ID(UUID())))
        #expect(Reminders.Read.Page.Input(page: .all).filter == .all)
        #expect(Reminders.Read.Output.self == AsyncThrowingStream<Reminders.Read.Value, any Error>.self)
        try await reminders(.update(.complete(reminder.id, true)))
        await #expect(throws: Reminders.Read.Error.notFound) { try await reminders(.read(Reminder.ID(UUID()))) }
    }

    @Test func `reads are called with the declared labels`() async throws {
        let reminders = reminders()
        #expect(try await reminders.read().first(where: { _ in true })?.lists.map(\.count) == [1])
        #expect(try reminders.read(reminder.id) == reminder)
        #expect(try await reminders.read(page: .list(list)).first(where: { _ in true })?.rows == [reminder])
        #expect(try await reminders.read(page: .list(Models.List<Reminder>.ID(UUID()))).first(where: { _ in true })?.rows.isEmpty == true)
        #expect(throws: Reminders.Read.Error.notFound) { try reminders.read(Reminder.ID(UUID())) }
    }
}
