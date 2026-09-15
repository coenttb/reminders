public import Organizing
public import SwiftUI

extension Organizing.List {
    /// One list on the home screen: its colored badge, title, and open count;
    /// info and delete are swipe actions.
    public struct Row: SwiftUI.View {
        private var list: Organizing.List<Element>
        private var count: Int
        private var details: () -> Void
        private var delete: () -> Void
        @Environment(\.editMode) private var editMode

        public init(_ list: Organizing.List<Element>, count: Int, details: @escaping () -> Void, delete: @escaping () -> Void) {
            self.list = list
            self.count = count
            self.details = details
            self.delete = delete
        }
    }
}

extension Organizing.List.Row {
    public var body: some SwiftUI.View {
        // Stock geometry: 62 pt rows, the badge 16 pt from the title, the count 10 pt from a body-size chevron.
        HStack(spacing: 16) {
            Organizing.List<Element>.Badge(color: list.color.swiftUI)
            Text(list.title)
            Spacer()
            HStack(spacing: 10) {
                Text("\(count)").foregroundStyle(.secondary).monospacedDigit()
                if editMode?.wrappedValue.isEditing != true {
                    Image(systemName: "chevron.forward").foregroundStyle(.tertiary).font(.body.weight(.semibold))
                }
            }
        }
        .swipeActions {
            Button("Delete", systemImage: "trash", role: .destructive, action: delete)
            Button("Info", systemImage: "info.circle", action: details).tint(.gray)
        }
    }
}

extension Organizing.List {
    /// The circular list glyph in the list's color, sized for a row or a form preview.
    public struct Badge: SwiftUI.View {
        private var color: SwiftUI.Color
        private var size: CGFloat

        public init(color: SwiftUI.Color, size: CGFloat = 32) {
            self.color = color
            self.size = size
        }

        public var body: some SwiftUI.View {
            Image(systemName: "list.bullet")
                .font(.system(size: size * 0.5, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: size, height: size)
                .background(color, in: .circle)
        }
    }
}

extension Organizing.List {
    /// The Add List bar glyph as iOS 27 draws it: a bulleted page with a plus badge
    /// bottom-trailing. No SF Symbol carries that badge, so the page and the badge are composed.
    public struct AddGlyph: SwiftUI.View {
        public init() {}

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
}
