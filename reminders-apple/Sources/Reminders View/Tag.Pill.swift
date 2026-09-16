public import Organizing
public import SwiftUI

extension Tag {
    public struct Pill: SwiftUI.View {
        private var title: String

        public init(title: String) {
            self.title = title
        }
    }
}

extension Tag.Pill {
    public var body: some SwiftUI.View {
        Text(title)
            .font(.body)
            .foregroundStyle(.primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(SwiftUI.Color(.tertiarySystemFill), in: .capsule)
    }
}
