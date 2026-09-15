public import Reminders
public import SQLiteData
public import Tagged

extension Lists {
    /// One row holding which detail is open and which reminder is being edited in place.
    @Table("listsState")
    public struct Record: Identifiable, Sendable {
        public let id: Int
        public var detail: Lists.Detail.ID?
        public var editing: Reminder.ID?

        public init(id: Int = 1, detail: Lists.Detail?, editing: Reminder.ID?) {
            self.id = id
            self.detail = detail?.id
            self.editing = editing
        }
    }
}

extension Lists.Detail.Preference {
    /// One row per detail the user adjusted.
    @Table("preferences")
    public struct Record: Identifiable, Sendable {
        @Column(primaryKey: true)
        public var detailID: Lists.Detail.ID
        public var ordering = ""
        public var showCompleted = false

        public var id: Lists.Detail.ID { detailID }

        public init(detailID: Lists.Detail.ID, _ preference: Lists.Detail.Preference) {
            self.detailID = detailID
            ordering = preference.ordering.rawValue
            showCompleted = preference.showCompleted
        }
    }
}

extension Lists.Detail.Preference.Record {
    public var preference: Lists.Detail.Preference {
        Lists.Detail.Preference(ordering: Lists.Ordering(rawValue: ordering) ?? .dueDate, showCompleted: showCompleted)
    }
}
