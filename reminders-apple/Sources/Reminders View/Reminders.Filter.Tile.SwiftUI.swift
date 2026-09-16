public import Reminders
public import Reminders_Feature
public import SwiftUI

extension Reminders.Filter.Tile {
    public struct SwiftUI {
        private var tile: Reminders.Filter.Tile
        private var style: Reminders.Filter.Style

        public init(tile: Reminders.Filter.Tile, style: Reminders.Filter.Style) {
            self.tile = tile
            self.style = style
        }
    }
}

extension Reminders.Filter.Tile.SwiftUI: SwiftUI::View {
    @ViewBuilder public var body: some SwiftUI::View {
        let title = style.title ?? ""
        Button { tile.open(tile.filter) } label: {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top) {
                    Image(systemName: style.symbol)
                        .font(.system(size: 24, weight: .medium))
                        .frame(width: 30, height: 30, alignment: .topLeading)
                    Spacer(minLength: 0)
                    if let count = tile.count {
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
        .accessibilityLabel(tile.count.map { "\(title), \($0) reminders" } ?? title)
    }
}
