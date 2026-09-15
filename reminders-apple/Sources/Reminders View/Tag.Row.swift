public import Organizing
public import SwiftUI

extension Tag {
    /// One tag on the home screen.
    public struct Row: SwiftUI.View {
        private var tag: Tag

        public init(_ tag: Tag) {
            self.tag = tag
        }
    }
}

extension Tag.Row {
    public var body: some SwiftUI.View {
        HStack(spacing: 14) {
            Image(systemName: "number")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 32, height: 32)
                .background(SwiftUI.Color.gray.gradient, in: .circle)
            Text(tag.title)
            Spacer()
            Image(systemName: "chevron.forward").foregroundStyle(.tertiary).font(.footnote.weight(.semibold))
        }
        .padding(.vertical, 4)
    }
}
