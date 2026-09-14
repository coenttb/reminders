public import Reminders
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
        HStack {
            Image(systemName: "number.circle.fill")
                .font(.largeTitle)
                .foregroundStyle(.gray)
                .background(Color.white.clipShape(Circle()).padding(4))
            Text(tag.title)
            Spacer()
            Image(systemName: "chevron.right").foregroundStyle(.gray).font(.footnote)
        }
    }
}
