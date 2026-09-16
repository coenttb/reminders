public import Foundation
public import Organizing
public import Reminders
import Reminders_Interface

extension Reminders.Feature.State {
    mutating func endEditing(_ session: UUID?) {
        guard let session, editing?.session == session else { return }
        editing = nil
    }

    mutating func modifyReminderForm(_ session: UUID, _ body: (inout Reminder.Draft.Feature.State) -> Void) {
        guard case var .reminder(form) = destination, form.session == session else { return }
        body(&form)
        destination = .reminder(form)
    }

    mutating func modifyListForm(_ session: UUID, _ body: (inout List<Reminder>.Draft.Feature.State) -> Void) {
        guard case var .list(form) = destination, form.session == session else { return }
        body(&form)
        destination = .list(form)
    }
}
