public import Reminder

extension Reminder {
    // The one row being edited has two fields; the card keeps its identity as the editing moves between rows.
    public enum Focus: Hashable, Sendable {
        case title
        case notes
    }
}
