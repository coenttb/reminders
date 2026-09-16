public import Organizing
public import Reminders
public import Reminders_SQL
public import SwiftUI
public import Tagged

extension Tag<Reminder> {
    public struct Cloud {
        private var tags: [Tag<Reminder>.Record]
        private var open: ([Tag<Reminder>.ID]) -> Void
        private var delete: (Tag<Reminder>.ID) -> Void

        public init(_ tags: [Tag<Reminder>.Record], open: @escaping ([Tag<Reminder>.ID]) -> Void, delete: @escaping (Tag<Reminder>.ID) -> Void) {
            self.tags = tags
            self.open = open
            self.delete = delete
        }
    }
}

extension Tag<Reminder>.Cloud: SwiftUI::View {
    public var body: some SwiftUI::View {
        Flow(spacing: 8) {
            Button { open(tags.map(\.id)) } label: { Tag<Reminder>.Pill(title: "All Tags") }
            ForEach(tags) { tag in
                Button { open([tag.id]) } label: { Tag<Reminder>.Pill(title: Tag<Reminder>.hashtag(tag.id)) }
                    .contextMenu {
                        Button("Delete Tag", systemImage: "trash", role: .destructive) { delete(tag.id) }
                    }
            }
        }
        .buttonStyle(.plain)
        .padding(.vertical, 4)
    }
}
