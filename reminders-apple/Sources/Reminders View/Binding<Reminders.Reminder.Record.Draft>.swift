import Foundation
import Reminders
import Reminders_SQL
import SwiftUI

extension Binding<Reminders.Reminder.Record.Draft> {
    func dueOn(_ now: Date, calendar: Calendar) -> Binding<Bool> { self[dynamicMember: \.[dueOn: now, calendar: calendar]] }
    func timeOn(_ now: Date, calendar: Calendar) -> Binding<Bool> { self[dynamicMember: \.[timeOn: now, calendar: calendar]] }
    func date(or fallback: Date) -> Binding<Date> { self[dynamicMember: \.[date: fallback]] }
}
