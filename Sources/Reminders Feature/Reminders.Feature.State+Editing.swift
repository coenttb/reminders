public import Foundation
import Reminders

extension Reminders.Feature.State {
    /// Closes the row being edited if it is still the one `session` opened.
    mutating func endEditing(_ session: UUID?) {
        guard let session, editing?.session == session else { return }
        editing = nil
    }
}
