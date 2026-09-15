public import Foundation
public import Tagged

extension Reminder {
    /// A list reminders belong to: named, colored, ordered by the user.
    public struct List: Identifiable, Hashable, Sendable {
        public typealias ID = Tagged<List, UUID>

        public var id: ID
        public var title: String
        public var color: Color
        public var position: Int

        public init(id: ID, title: String = "", color: Color = .default, position: Int = 0) {
            self.id = id
            self.title = title
            self.color = color
            self.position = position
        }
    }
}

extension Reminder.List {
    /// The list that exists when no other does.
    public static func `default`(id: ID) -> Self {
        Reminder.List(id: id, title: "Personal", color: .default)
    }

    /// A name of only whitespace is no list.
    public var isBlank: Bool { title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
}

extension Reminder.List {
    /// An sRGB color with unit components; platform-free, so the stored form and the views both map from it.
    public struct Color: Hashable, Sendable {
        public var red: Double
        public var green: Double
        public var blue: Double

        public init(red: Double, green: Double, blue: Double) {
            self.red = red
            self.green = green
            self.blue = blue
        }
    }
}

extension Reminder.List.Color {
    public static let `default` = Reminder.List.Color(hex: 0x4a99ef)

    /// From `0xRRGGBB`.
    public init(hex: Int64) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 0xFF,
            green: Double((hex >> 8) & 0xFF) / 0xFF,
            blue: Double(hex & 0xFF) / 0xFF
        )
    }

    /// As `0xRRGGBB`; the stored form keeps this integer.
    public var hex: Int64 {
        func byte(_ component: Double) -> Int64 { Int64((min(max(component, 0), 1) * 0xFF).rounded()) }
        return byte(red) << 16 | byte(green) << 8 | byte(blue)
    }
}
