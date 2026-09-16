public import Reminders
public import SwiftUI

extension Reminder.Filter {
    public struct Tile: SwiftUI.View {
        private var filter: Reminder.Filter
        private var glyph: Glyph
        private var fill: Fill
        private var count: Int?
        private var open: (Reminder.Filter) -> Void

        public init(_ filter: Reminder.Filter, glyph: Glyph, fill: Fill, count: Int?, open: @escaping (Reminder.Filter) -> Void) {
            self.filter = filter
            self.glyph = glyph
            self.fill = fill
            self.count = count
            self.open = open
        }
    }
}

extension Reminder.Filter.Tile {
    public struct Fill: Hashable, Sendable {
        public var top: SwiftUI.Color
        public var bottom: SwiftUI.Color

        public init(top: SwiftUI.Color, bottom: SwiftUI.Color) {
            self.top = top
            self.bottom = bottom
        }

        public static let today = Fill(top: .init(red: 125 / 255, green: 195 / 255, blue: 239 / 255), bottom: .init(red: 102 / 255, green: 185 / 255, blue: 237 / 255))
        public static let scheduled = Fill(top: .init(red: 241 / 255, green: 157 / 255, blue: 156 / 255), bottom: .init(red: 238 / 255, green: 142 / 255, blue: 140 / 255))
        public static let all = Fill(top: .init(red: 106 / 255, green: 106 / 255, blue: 106 / 255), bottom: .init(red: 80 / 255, green: 80 / 255, blue: 80 / 255))
        public static let flagged = Fill(top: .init(red: 243 / 255, green: 176 / 255, blue: 108 / 255), bottom: .init(red: 240 / 255, green: 160 / 255, blue: 84 / 255))
        public static let completed = Fill(top: .init(red: 166 / 255, green: 174 / 255, blue: 179 / 255), bottom: .init(red: 155 / 255, green: 163 / 255, blue: 169 / 255))
    }

    public enum Glyph: Hashable, Sendable {
        case symbol(String)
        case today(day: Int)
    }
}

extension Reminder.Filter.Tile {
    @ViewBuilder public var body: some SwiftUI.View {
        let title = filter.title ?? ""
        Button { open(filter) } label: {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top) {
                    glyphView.frame(width: 30, height: 30, alignment: .topLeading)
                    Spacer(minLength: 0)
                    if let count {
                        Text("\(count)")
                            .font(.system(.title, design: .rounded).weight(.bold))
                            .monospacedDigit()
                            .offset(y: -4)
                    }
                }
                Spacer(minLength: 0)
                Text(title).font(.title3.weight(.semibold)).lineLimit(1)
            }
            .foregroundStyle(.white)
            .padding(EdgeInsets(top: 11, leading: 14, bottom: 7, trailing: 12))
            .frame(maxWidth: .infinity, minHeight: 80, alignment: .leading)
            .background(LinearGradient(colors: [fill.top, fill.bottom], startPoint: .top, endPoint: .bottom), in: .rect(cornerRadius: 18))
            .contentShape(.rect(cornerRadius: 18))
        }
        .accessibilityLabel(count.map { "\(title), \($0) reminders" } ?? title)
    }

    @ViewBuilder private var glyphView: some SwiftUI.View {
        switch glyph {
        case let .symbol(name):
            Image(systemName: name).font(.system(size: 24, weight: .medium))
        case let .today(day):
            Image(systemName: "\(day).calendar").font(.system(size: 24, weight: .medium))
        }
    }
}

extension Reminder.Filter {
    public static func smart(flagged: Bool) -> [Reminder.Filter] {
        flagged ? [.today, .scheduled, .all, .flagged, .completed] : [.today, .scheduled, .all, .completed]
    }
}

extension Reminder.Filter.Tile {
    @ViewBuilder public static func badge(for filter: Reminder.Filter, day: Int) -> some SwiftUI.View {
        let (name, fill): (String, Fill) = switch filter {
        case .today: ("\(day).calendar", .today)
        case .scheduled: ("calendar", .scheduled)
        case .all: ("tray.fill", .all)
        case .flagged: ("flag.fill", .flagged)
        case .completed: ("checkmark", .completed)
        case .list, .tags: ("list.bullet", .all)
        }
        Image(systemName: name)
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: 32, height: 32)
            .background(fill.bottom, in: .circle)
    }
}
