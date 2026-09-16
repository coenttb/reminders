public import Organizing
public import SwiftUI

extension Organizing.List {
    public struct Badge: SwiftUI.View {
        private var color: SwiftUI.Color
        private var size: CGFloat

        public init(color: SwiftUI.Color, size: CGFloat = 32) {
            self.color = color
            self.size = size
        }
    }
}

extension Organizing.List.Badge {
    public var body: some SwiftUI.View {
        Image(systemName: "list.bullet")
            .font(.system(size: size * 0.5, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(color, in: .circle)
    }
}
