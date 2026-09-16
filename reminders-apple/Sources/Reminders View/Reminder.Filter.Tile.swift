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
