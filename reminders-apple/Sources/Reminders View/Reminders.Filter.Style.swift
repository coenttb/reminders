public import Models
public import Reminder
public import Reminders
public import Reminders_SQL
public import SwiftUI
import Tagged

extension Reminders.Filter {
    public struct Style {
        public var title: String?
        public var tint: SwiftUI.Color
        public var fill: Fill
        public var symbol: String

        public init(title: String?, tint: SwiftUI.Color, fill: Fill, symbol: String) {
            self.title = title
            self.tint = tint
            self.fill = fill
            self.symbol = symbol
        }
    }
}

extension Reminders.Filter.Style {
    public init(_ filter: Reminders.Filter, list: Models.List<Reminder>.Record?, day: Int) {
        switch filter {
        case .all:
            self.init(title: "All", tint: .primary, fill: .all, symbol: "tray.fill")
        case .completed:
            self.init(title: "Completed", tint: .gray, fill: .completed, symbol: "checkmark")
        case .flagged:
            self.init(title: "Flagged", tint: .orange, fill: .flagged, symbol: "flag.fill")
        case .list:
            self.init(title: list?.title, tint: list.map { SwiftUI.Color(Models.Color($0.color)) } ?? .blue, fill: .all, symbol: "list.bullet")
        case .scheduled:
            self.init(title: "Scheduled", tint: .red, fill: .scheduled, symbol: "calendar")
        case let .tags(tags):
            let title = tags.count == 1 ? tags.first.map(Tag<Reminder>.hashtag) : tags.isEmpty ? "Tags" : "\(tags.count) tags"
            self.init(title: title, tint: .blue, fill: .all, symbol: "list.bullet")
        case .today:
            self.init(title: "Today", tint: .blue, fill: .today, symbol: "\(day).calendar")
        }
    }

    public static func smart(flagged: Bool) -> [Reminders.Filter] {
        flagged ? [.today, .scheduled, .all, .flagged, .completed] : [.today, .scheduled, .all, .completed]
    }

    @ViewBuilder public static func badge(for filter: Reminders.Filter, day: Int) -> some SwiftUI.View {
        let style = Self(filter, list: nil, day: day)
        Image(systemName: style.symbol)
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: 32, height: 32)
            .background(style.fill.bottom, in: .circle)
    }
}
