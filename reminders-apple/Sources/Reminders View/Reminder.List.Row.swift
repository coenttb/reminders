public import Reminders
public import SwiftUI

extension Reminder.List {
    /// One list on the home screen with its open count; details and delete are swipe actions.
    public struct Row: SwiftUI.View {
        private var list: Reminder.List
        private var count: Int
        private var details: () -> Void
        private var delete: () -> Void

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
        HStack {
            Image(systemName: "list.bullet.circle.fill")
                .font(.largeTitle)
                .foregroundStyle(list.color.swiftUI)
                .background(Color.white.clipShape(Circle()).padding(4))
            Text(list.title)
            Spacer()
            Text("\(count)").foregroundStyle(.gray)
            Image(systemName: "chevron.right").foregroundStyle(.gray).font(.footnote)
        }
        .swipeActions {
            Button(role: .destructive, action: delete) { Image(systemName: "trash") }
            Button(action: details) { Image(systemName: "info.circle") }
        }
    }
}
