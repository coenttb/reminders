public import Organizing
public import SwiftUI

extension Organizing.List {
    public struct AddGlyph: SwiftUI.View {
        public init() {}
    }
}

extension Organizing.List.AddGlyph {
    public var body: some SwiftUI.View {
        Image(systemName: "list.bullet.rectangle.portrait")
            .overlay(alignment: .bottomTrailing) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 11, weight: .bold))
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.white, .primary)
                    .background(.background, in: .circle)
                    .offset(x: 4, y: 3)
            }
    }
}
