public import Models
public import Reminder
import Reminders
public import Reminders_Interface
public import Reminders_SQL
public import SwiftUI

extension Models.List<Reminder>.Row {
    public struct SwiftUI {
        private var list: Models.List<Reminder>.Record
        private var row: Models.List<Reminder>.Row
        @Environment(\.editMode) private var editMode

        public init(list: Models.List<Reminder>.Record, row: Models.List<Reminder>.Row) {
            self.list = list
            self.row = row
        }
    }
}

extension Models.List<Reminder>.Row.SwiftUI: SwiftUI::View {
    public var body: some SwiftUI::View {
        HStack(spacing: 16) {
            Models.List<Reminder>.Badge(color: SwiftUI::Color(Models.Color(list.color)))
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
