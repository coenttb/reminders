public import Reminders
public import SQLiteData

extension Lists {
    /// One row holding which detail is open.
    @Table("listsState")
    public struct Record: Identifiable, Sendable {
        public let id: Int
        public var detail: String?

        public init(id: Int = 1, detail: Lists.Detail?) {
            self.id = id
            self.detail = detail?.id
        }
    }
}

extension Lists.Detail.Preference {
    /// One row per detail the user adjusted.
    @Table("preferences")
    public struct Record: Identifiable, Sendable {
        @Column(primaryKey: true)
        public var detailID: String
        public var ordering = ""
        public var showCompleted = false

        public var id: String { detailID }

        public init(detailID: String, _ preference: Lists.Detail.Preference) {
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
