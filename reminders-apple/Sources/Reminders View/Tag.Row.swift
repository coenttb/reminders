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
        HStack(spacing: 16) {
            Image(systemName: "number")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 32, height: 32)
                .background(SwiftUI.Color.gray, in: .circle)
            Text(tag.title)
            Spacer()
            Image(systemName: "chevron.forward").foregroundStyle(.tertiary).font(.body.weight(.semibold))
        }
    }
}
