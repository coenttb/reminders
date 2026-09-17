public import Reminders
public import SwiftUI

extension Reminders.Filter {
    public enum Tile {}
}

extension Reminders.Filter.Tile {
    public struct SwiftUI {
        private var filter: Reminders.Filter
        private var count: Int?
        private var style: Reminders.Filter.Style
        private var open: () -> Void

        public init(filter: Reminders.Filter, count: Int?, style: Reminders.Filter.Style, open: @escaping () -> Void) {
            self.filter = filter
            self.count = count
            self.style = style
            self.open = open
        }
    }
}

extension Reminders.Filter.Tile.SwiftUI: SwiftUI::View {
    @ViewBuilder public var body: some SwiftUI::View {
        let title = style.title ?? ""
        Button(action: open) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top) {
                    Image(systemName: style.symbol)
                        .font(.system(size: 24, weight: .medium))
                        .frame(width: 30, height: 30, alignment: .topLeading)
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
            .background(LinearGradient(colors: [style.fill.top, style.fill.bottom], startPoint: .top, endPoint: .bottom), in: .rect(cornerRadius: 18))
            .contentShape(.rect(cornerRadius: 18))
        }
        .accessibilityLabel(count.map { "\(title), \($0) reminders" } ?? title)
    }
}
