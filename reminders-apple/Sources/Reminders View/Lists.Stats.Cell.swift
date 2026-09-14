public import SwiftUI
public import Reminders

extension Lists.Stats {
    /// One tile of the home grid: icon, name, and an optional count.
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
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 8) {
                    Image(systemName: systemImage)
                        .font(.largeTitle).bold()
                        .foregroundStyle(color)
                        .background(Color.white.clipShape(Circle()).padding(4))
                    Text(title).font(.headline).foregroundStyle(.gray).bold().padding(.leading, 4)
                }
                Spacer()
                if let count {
                    Text("\(count)").font(.largeTitle).fontDesign(.rounded).bold().foregroundStyle(.primary)
                }
            }
            .padding(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(10)
        }
    }
}
