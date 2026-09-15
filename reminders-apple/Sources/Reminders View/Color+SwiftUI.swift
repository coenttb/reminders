public import Organizing
public import Reminders
public import SwiftUI

extension Organizing.Color {
    /// The domain color as SwiftUI draws it; settable, so a picker binds to it through
    /// a key path (`$list.color.swiftUI`) and SwiftUI keeps the transaction.
    public var swiftUI: SwiftUI.Color {
        get { SwiftUI.Color(red: red, green: green, blue: blue) }
        set { self = Organizing.Color(newValue) }
    }

    /// From a picked SwiftUI color, resolved in the default environment.
    public init(_ color: SwiftUI.Color) {
        let resolved = color.resolve(in: EnvironmentValues())
        self.init(red: Double(resolved.red), green: Double(resolved.green), blue: Double(resolved.blue))
    }
}

extension Reminder.Filter {
    /// The accent of a filter: its list's color, or the smart group's.
    public func color(list: Organizing.Color?) -> SwiftUI.Color {
        switch self {
        case .all: .primary
        case .completed: .gray
        case .flagged: .orange
        case .list: list?.swiftUI ?? .blue
        case .scheduled: .red
        case .tags, .today: .blue
        }
    }
}
