public import Reminders

extension Reminders.Filter.Tile {
    public enum Glyph: Hashable, Sendable {
        case symbol(String)
        case today(day: Int)
    }
}
