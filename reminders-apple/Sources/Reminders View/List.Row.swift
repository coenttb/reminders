public import Organizing
public import SwiftUI

extension Organizing.List {
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
        HStack(spacing: 16) {
            Organizing.List<Element>.Badge(color: list.color.swiftUI)
            Text(list.title)
            Spacer()
            HStack(spacing: 10) {
                if editMode?.wrappedValue.isEditing == true {
                    Button("Info", systemImage: "info.circle", action: details)
                        .labelStyle(.iconOnly)
                        .font(.title3)
                        .buttonStyle(.borderless)
                } else {
                    Text("\(count)").foregroundStyle(.secondary).monospacedDigit()
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
