public import Reminders
public import SwiftUI

extension Reminders.Filter.Style {
    public struct Fill: Hashable, Sendable {
        public var top: SwiftUI.Color
        public var bottom: SwiftUI.Color

        public init(top: SwiftUI.Color, bottom: SwiftUI.Color) {
            self.top = top
            self.bottom = bottom
        }
    }
}

extension Reminders.Filter.Style.Fill {
    public static let today: Self = .init(
        top: .init(red: 125 / 255, green: 195 / 255, blue: 239 / 255),
        bottom: .init(red: 102 / 255, green: 185 / 255, blue: 237 / 255)
    )
    public static let scheduled: Self = .init(
        top: .init(red: 241 / 255, green: 157 / 255, blue: 156 / 255),
        bottom: .init(red: 238 / 255, green: 142 / 255, blue: 140 / 255)
    )
    public static let all: Self = .init(
        top: .init(red: 106 / 255, green: 106 / 255, blue: 106 / 255),
        bottom: .init(red: 80 / 255, green: 80 / 255, blue: 80 / 255)
    )
    public static let flagged: Self = .init(
        top: .init(red: 243 / 255, green: 176 / 255, blue: 108 / 255),
        bottom: .init(red: 240 / 255, green: 160 / 255, blue: 84 / 255)
    )
    public static let completed: Self = .init(
        top: .init(red: 166 / 255, green: 174 / 255, blue: 179 / 255),
        bottom: .init(red: 155 / 255, green: 163 / 255, blue: 169 / 255)
    )
}
