public import Reminders
public import SwiftUI

extension Reminder.List {
    /// One list on the home screen: its colored badge, title, and open count;
    /// info and delete are swipe actions.
    public struct Row: SwiftUI.View {
        private var list: Reminder.List
        private var count: Int
        private var details: () -> Void
        private var delete: () -> Void
        @Environment(\.editMode) private var editMode

        public init(_ list: Reminder.List, count: Int, details: @escaping () -> Void, delete: @escaping () -> Void) {
            self.list = list
            self.count = count
            self.details = details
            self.delete = delete
        }
    }
}

extension Reminder.List.Row {
    public var body: some SwiftUI.View {
        HStack(spacing: 14) {
            Reminder.List.Badge(color: list.color.swiftUI)
            Text(list.title)
            Spacer()
            Text("\(count)").foregroundStyle(.secondary).monospacedDigit()
            if editMode?.wrappedValue.isEditing != true {
                Image(systemName: "chevron.forward").foregroundStyle(.tertiary).font(.footnote.weight(.semibold))
            }
        }
        .padding(.vertical, 4)
        .swipeActions {
            Button("Delete", systemImage: "trash", role: .destructive, action: delete)
            Button("Info", systemImage: "info.circle", action: details).tint(.gray)
        }
    }
}

extension Reminder.List {
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
                .font(.system(size: size * 0.45, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: size, height: size)
                .background(color.gradient, in: .circle)
        }
    }
}
