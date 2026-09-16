import Foundation
import Reminders

extension Reminders.Feature.State {
    mutating func endEditing(_ session: UUID?) {
        guard let session, editing?.session == session else { return }
        editing = nil
    }
}
