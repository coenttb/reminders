public import Organizing
public import SwiftUI

extension Tag {
    /// The home's Tags card as iOS 27 draws it: one card of capsules that wrap, "All Tags"
    /// first, then each tag as its hashtag. A tap opens the tag; a long press offers Delete.
    public struct Cloud: SwiftUI.View {
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

extension Tag.Cloud {
    public var body: some SwiftUI.View {
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

extension Tag {
    /// One capsule of the cloud: body text on a gray fill.
    public struct Pill: SwiftUI.View {
        private var title: String

        public init(title: String) {
            self.title = title
        }

        public var body: some SwiftUI.View {
            Text(title)
                .font(.body)
                .foregroundStyle(.primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(SwiftUI.Color(.tertiarySystemFill), in: .capsule)
        }
    }
}

extension Tag.Cloud {
    /// Lays subviews out left to right, wrapping to a new line when the width runs out.
    struct Flow: Layout {
        var spacing: CGFloat

        func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
            let width = proposal.replacingUnspecifiedDimensions().width
            return CGSize(width: width, height: place(in: width, subviews: subviews).size.height)
        }

        func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
            let placed = place(in: bounds.width, subviews: subviews)
            for (subview, origin) in zip(subviews, placed.origins) {
                subview.place(at: CGPoint(x: bounds.minX + origin.x, y: bounds.minY + origin.y), proposal: .unspecified)
            }
        }

        private func place(in width: CGFloat, subviews: Subviews) -> (size: CGSize, origins: [CGPoint]) {
            var origins: [CGPoint] = []
            var x: CGFloat = 0, y: CGFloat = 0, lineHeight: CGFloat = 0, widest: CGFloat = 0
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                if x > 0, x + size.width > width {
                    x = 0
                    y += lineHeight + spacing
                    lineHeight = 0
                }
                origins.append(CGPoint(x: x, y: y))
                x += size.width + spacing
                lineHeight = max(lineHeight, size.height)
                widest = max(widest, x - spacing)
            }
            return (CGSize(width: widest, height: y + lineHeight), origins)
        }
    }
}
