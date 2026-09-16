public import Organizing
public import SwiftUI

extension Organizing.List {
    public struct Row {
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

extension Organizing.List.Row: SwiftUI::View {
    public var body: some SwiftUI::View {
        HStack(spacing: 16) {
            Organizing.List<Element>.Badge(color: SwiftUI.Color(list.color))
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
