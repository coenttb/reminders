public import Organizing
public import Reminders
public import Reminders_Interface
public import Reminders_SQL
public import SwiftUI

extension Organizing.List<Reminder>.Row {
    public struct SwiftUI {
        private var list: Organizing.List<Reminder>.Record
        private var row: Organizing.List<Reminder>.Row
        @Environment(\.editMode) private var editMode

        public init(list: Organizing.List<Reminder>.Record, row: Organizing.List<Reminder>.Row) {
            self.list = list
            self.row = row
        }
    }
}

extension Organizing.List<Reminder>.Row.SwiftUI: SwiftUI::View {
    public var body: some SwiftUI::View {
        HStack(spacing: 16) {
            Organizing.List<Reminder>.Badge(color: SwiftUI::Color(Organizing.Color(list.color)))
            Text(list.title)
            Spacer()
            HStack(spacing: 10) {
                if editMode?.wrappedValue.isEditing == true {
                    Button("Info", systemImage: "info.circle", action: row.actions.details)
                        .labelStyle(.iconOnly)
                        .font(.title3)
                        .buttonStyle(.borderless)
                } else {
                    Text("\(row.count)").foregroundStyle(.secondary).monospacedDigit()
                    Image(systemName: "chevron.forward").foregroundStyle(.tertiary).font(.body.weight(.semibold))
                }
            }
        }
        .swipeActions {
            Button("Delete", systemImage: "trash", role: .destructive, action: row.actions.delete)
            Button("Info", systemImage: "info.circle", action: row.actions.details).tint(.gray)
        }
    }
}
