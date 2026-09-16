public import Organizing
public import SwiftUI

extension Tag {
    public struct Cloud {
        private var tags: [Tag]
        private var open: ([Tag.ID]) -> Void
        private var delete: (Tag.ID) -> Void

        public init(_ tags: [Tag], open: @escaping ([Tag.ID]) -> Void, delete: @escaping (Tag.ID) -> Void) {
            self.tags = tags
            self.open = open
            self.delete = delete
        }
    }
}

extension Tag.Cloud: SwiftUI::View {
    public var body: some SwiftUI::View {
        Flow(spacing: 8) {
            Button { open(tags.map(\.id)) } label: { Tag.Pill(title: "All Tags") }
            ForEach(tags) { tag in
                Button { open([tag.id]) } label: { Tag.Pill(title: Tag.hashtag(tag.id)) }
                    .contextMenu {
                        Button("Delete Tag", systemImage: "trash", role: .destructive) { delete(tag.id) }
                    }
            }
        }
        .buttonStyle(.plain)
        .padding(.vertical, 4)
    }
}
