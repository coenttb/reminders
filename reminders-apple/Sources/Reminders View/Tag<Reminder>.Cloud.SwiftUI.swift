public import Models
public import Reminder
public import Reminders_Interface
public import Reminders_SQL
public import SwiftUI
import Tagged

extension Tag<Reminder>.Cloud {
    public struct SwiftUI {
        private var tags: [Tag<Reminder>.Record]
        private var cloud: Tag<Reminder>.Cloud

        public init(tags: [Tag<Reminder>.Record], cloud: Tag<Reminder>.Cloud) {
            self.tags = tags
            self.cloud = cloud
        }
    }
}

extension Tag<Reminder>.Cloud.SwiftUI: SwiftUI::View {
    public var body: some SwiftUI::View {
        Tag<Reminder>.Cloud.Flow(spacing: 8) {
            Button { cloud.actions.open(tags.map(\.id)) } label: { Tag<Reminder>.Pill(title: "All Tags") }
            ForEach(tags) { tag in
                Button { cloud.actions.open([tag.id]) } label: { Tag<Reminder>.Pill(title: Tag<Reminder>.hashtag(tag.id)) }
                    .contextMenu {
                        Button("Delete Tag", systemImage: "trash", role: .destructive) { cloud.actions.delete(tag.id) }
                    }
            }
        }
        .buttonStyle(.plain)
        .padding(.vertical, 4)
    }
}
