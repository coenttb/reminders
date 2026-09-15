public import Reminders
public import SwiftUI

extension Reminder.Filter {
    /// One tile of the home grid, solid in its color: the white icon top-leading,
    /// the count top-trailing, the filter's name bottom-leading.
    public struct Cell: SwiftUI.View {
        private var filter: Reminder.Filter
        private var systemImage: String
        private var color: SwiftUI.Color
        private var count: Int?
        private var open: (Reminder.Filter) -> Void

        public init(_ filter: Reminder.Filter, systemImage: String, color: SwiftUI.Color, count: Int?, open: @escaping (Reminder.Filter) -> Void) {
            self.filter = filter
            self.systemImage = systemImage
            self.color = color
            self.count = count
            self.open = open
        }
    }
}

extension Reminder.Filter.Cell {
    @ViewBuilder public var body: some SwiftUI.View {
        let title = filter.title ?? ""
        Button { open(filter) } label: {
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .top) {
                    Image(systemName: systemImage)
                        .font(.title2.weight(.semibold))
                        .frame(width: 34, height: 34)
                        .background(.white.opacity(0.25), in: .rect(cornerRadius: 8))
                    Spacer()
                    if let count {
                        Text("\(count)").font(.title.weight(.bold)).fontDesign(.rounded).monospacedDigit()
                    }
                }
                Text(title).font(.headline)
            }
            .foregroundStyle(.white)
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(color.gradient.opacity(0.9), in: .rect(cornerRadius: 16))
            .saturation(0.85)
            .contentShape(.rect(cornerRadius: 16))
        }
        .accessibilityLabel(count.map { "\(title), \($0) reminders" } ?? title)
    }
}
