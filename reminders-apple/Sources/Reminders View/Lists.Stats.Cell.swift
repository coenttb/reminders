public import SwiftUI
public import Reminders

extension Lists.Stats {
    /// One tile of the home grid, solid in its color: the white icon top-leading,
    /// the count top-trailing, the name bottom-leading.
    public struct Cell: SwiftUI.View {
        private var title: String
        private var systemImage: String
        private var color: Color
        private var count: Int?
        private var action: () -> Void

        public init(_ title: String, systemImage: String, color: Color, count: Int?, action: @escaping () -> Void) {
            self.title = title
            self.systemImage = systemImage
            self.color = color
            self.count = count
            self.action = action
        }
    }
}

extension Lists.Stats.Cell {
    public var body: some SwiftUI.View {
        Button(action: action) {
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
