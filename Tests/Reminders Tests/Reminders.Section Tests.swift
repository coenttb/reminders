import Foundation
import Models
import Reminder
import Reminders
import Tagged
import Testing

@Suite struct `Reminders sections` {
    let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Amsterdam")!
        return calendar
    }()
    let list = Models.List<Reminder>.ID(UUID(uuidString: "00000000-0000-0000-0000-000000000000")!)
    let friday: Date

    init() throws {
        friday = try #require(calendar.date(from: DateComponents(year: 2026, month: 9, day: 18, hour: 9, minute: 41)))
    }

    func date(_ day: Int, month: Int = 9, year: Int = 2026, hour: Int? = nil) throws -> Date {
        try #require(calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour ?? 0)))
    }

    func reminder(due: Reminder.Due?) -> Reminder {
        Reminder(id: Reminder.ID(UUID()), list: list, title: "Row", due: due, created: friday)
    }

    @Test func `Scheduled lists today, tomorrow, the five days after, the rest of the month, and twelve months`() throws {
        let sections = Reminders.Section.sections(for: .scheduled, at: friday, calendar: calendar)
        let days = try (20...24).map { try date($0) }
        let months = try (10...12).map { try date(1, month: $0) } + (1...9).map { try date(1, month: $0, year: 2027) }
        #expect(sections == [.today, .tomorrow] + days.map(Reminders.Section.day) + [.restOfMonth] + months.map(Reminders.Section.month))
        #expect(Reminders.Section.sections(for: .today, at: friday, calendar: calendar) == [.overdue(day: nil), .allDay, .morning, .afternoon, .tonight])
        #expect(Reminders.Section.sections(for: .list(list), at: friday, calendar: calendar).isEmpty)
    }

    @Test func `a row falls into the section its due date names`() throws {
        func section(_ due: Reminder.Due?, in filter: Reminders.Filter) -> Reminders.Section {
            Reminders.Section.section(of: reminder(due: due), in: filter, at: friday, calendar: calendar)
        }
        #expect(section(.day(try date(16)), in: .scheduled) == .overdue(day: try date(16)))
        #expect(section(.moment(try date(18, hour: 15)), in: .scheduled) == .today)
        #expect(section(.day(try date(19)), in: .scheduled) == .tomorrow)
        #expect(section(.day(try date(21)), in: .scheduled) == .day(try date(21)))
        #expect(section(.day(try date(24)), in: .scheduled) == .day(try date(24)))
        #expect(section(.day(try date(25)), in: .scheduled) == .restOfMonth)
        #expect(section(.day(try date(3, month: 10)), in: .scheduled) == .month(try date(1, month: 10)))
        #expect(section(.day(try date(3, month: 11, year: 2027)), in: .scheduled) == .month(try date(1, month: 11, year: 2027)))
        #expect(section(.day(try date(16)), in: .today) == .overdue(day: nil))
        #expect(section(.day(try date(18)), in: .today) == .allDay)
        #expect(section(.moment(try date(18, hour: 11)), in: .today) == .morning)
        #expect(section(.moment(try date(18, hour: 12)), in: .today) == .afternoon)
        #expect(section(.moment(try date(18, hour: 18)), in: .today) == .tonight)
        #expect(section(nil, in: .all) == .list(list) && section(nil, in: .list(list)) == .rows)
        #expect(Reminders.Section.tomorrow.contains(reminder(due: .day(try date(19))), in: .scheduled, at: friday, calendar: calendar))
        #expect(!Reminders.Section.today.contains(reminder(due: .day(try date(19))), in: .scheduled, at: friday, calendar: calendar))
    }

    @Test func `Completed sections by the completion day: today, the previous seven days, then months, newest first`() throws {
        func section(completed: Date) -> Reminders.Section {
            var reminder = reminder(due: nil)
            reminder.completed = completed
            return Reminders.Section.section(of: reminder, in: .completed, at: friday, calendar: calendar)
        }
        #expect(Reminders.Section.sections(for: .completed, at: friday, calendar: calendar) == [.today])
        #expect(section(completed: friday) == .today)
        #expect(section(completed: try date(15, hour: 5)) == .previous(day: try date(15)))
        #expect(section(completed: try date(11)) == .previous(day: try date(11)))
        #expect(section(completed: try date(10)) == .earlier(month: try date(1)))
        #expect(section(completed: try date(3, month: 7)) == .earlier(month: try date(1, month: 7)))
        let keys: [Reminders.Section] = [.earlier(month: try date(1, month: 7)), .previous(day: try date(11)), .today, .previous(day: try date(15)), .earlier(month: try date(1))]
        #expect(keys.sorted() == [.today, .previous(day: try date(15)), .previous(day: try date(11)), .earlier(month: try date(1)), .earlier(month: try date(1, month: 7))])
    }

    @Test func `a section names the date a row started in it takes`() throws {
        #expect(Reminders.Section.today.due(at: friday, calendar: calendar) == .day(try date(18)))
        #expect(Reminders.Section.tomorrow.due(at: friday, calendar: calendar) == .day(try date(19)))
        #expect(Reminders.Section.afternoon.due(at: friday, calendar: calendar) == .moment(try date(18, hour: 12)))
        #expect(Reminders.Section.restOfMonth.due(at: friday, calendar: calendar) == nil)
    }

    @Test func `a page folds its rows into the listed sections and slots the ones the rows bring in by date`() throws {
        let rows = try [reminder(due: .day(date(16))), reminder(due: .day(date(17))), reminder(due: .day(date(18))), reminder(due: .day(date(21))), reminder(due: .day(date(5, month: 2, year: 2028)))]
        let page = Reminders.Page(
            folding: rows,
            into: Reminders.Section.sections(for: .scheduled, at: friday, calendar: calendar),
            by: { Reminders.Section.section(of: $0, in: .scheduled, at: friday, calendar: calendar) },
            total: 5,
            completed: 0
        )
        #expect(page.sections.prefix(4).map(\.key) == [.overdue(day: try date(16)), .overdue(day: try date(17)), .today, .tomorrow])
        #expect(page.sections.last?.key == .month(try date(1, month: 2, year: 2028)))
        #expect(page.sections.count == 2 + 20 + 1)
        #expect(page.rows == rows)
        let monday = try date(21)
        #expect(page.sections.first { $0.key == .day(monday) }?.rows.count == 1)
        #expect(page.sections.filter { $0.rows.isEmpty }.count == 23 - 5)
        var edited = page
        let inserted = edited.insert(reminder(due: nil), after: rows[2].id)
        #expect(inserted && edited.rows.count == 6 && edited.sections[2].rows.count == 2)
        edited.removeAll { $0.id == rows[0].id }
        #expect(edited.sections[0].rows.isEmpty && edited.rows.count == 5)
    }
}
