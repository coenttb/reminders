public import Reminders
public import SwiftUI

extension Reminder.List.Color {
    /// The domain color as SwiftUI draws it.
    public var swiftUI: SwiftUI.Color { SwiftUI.Color(red: red, green: green, blue: blue) }

    /// From a picked SwiftUI color, resolved in the default environment.
    public init(_ color: SwiftUI.Color) {
        let resolved = color.resolve(in: EnvironmentValues())
        self.init(red: Double(resolved.red), green: Double(resolved.green), blue: Double(resolved.blue))
    }
}

extension Lists.Detail {
    /// The accent of a detail: its list's color, or the smart group's.
    public func color(in lists: Lists) -> SwiftUI.Color {
        switch self {
        case .all: .primary
        case .completed: .gray
        case .flagged: .orange
        case let .list(id): lists.list(id)?.color.swiftUI ?? .blue
        case .scheduled: .red
        case .tags, .today: .blue
        }
    }
}
