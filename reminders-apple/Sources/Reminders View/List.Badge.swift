public import Models
public import SwiftUI

extension Models.List {
    public struct Badge {
        private var color: SwiftUI.Color
        private var size: CGFloat

        public init(color: SwiftUI.Color, size: CGFloat = 32) {
            self.color = color
            self.size = size
        }
    }
}

extension Models.List.Badge: SwiftUI::View {
    public var body: some SwiftUI::View {
        Image(systemName: "list.bullet")
            .font(.system(size: size * 0.5, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(color, in: .circle)
    }
}
