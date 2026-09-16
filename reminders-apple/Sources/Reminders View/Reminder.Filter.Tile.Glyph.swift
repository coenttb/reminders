public import Reminders

extension Reminder.Filter.Tile {
    public enum Glyph: Hashable, Sendable {
        case symbol(String)
        case today(day: Int)
    }
}
