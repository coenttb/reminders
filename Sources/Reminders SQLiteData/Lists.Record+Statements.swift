public import Reminders
public import SQLiteData
public import Tagged

extension Lists.Detail.Preference.Record {
    /// The preference a detail has, or its default when none was stored.
    public static func preference(for detail: Lists.Detail) -> Where<Lists.Detail.Preference.Record> {
        Lists.Detail.Preference.Record.find(detail.id)
    }

    /// Sets a detail's ordering, leaving show-completed as it is (or at its default for a detail
    /// never adjusted).
    public static func set(ordering: Lists.Ordering, for detail: Lists.Detail) -> InsertOf<Lists.Detail.Preference.Record> {
        var preference = detail.defaultPreference
        preference.ordering = ordering
        return Lists.Detail.Preference.Record.insert {
            Lists.Detail.Preference.Record(detailID: detail.id, preference)
        } onConflict: {
            $0.detailID
        } doUpdate: { row, excluded in
            row.ordering = excluded.ordering
        }
    }

    /// Flips a detail's show-completed, leaving the ordering as it is.
    public static func toggleShowCompleted(for detail: Lists.Detail) -> InsertOf<Lists.Detail.Preference.Record> {
        var preference = detail.defaultPreference
        preference.showCompleted.toggle()
        return Lists.Detail.Preference.Record.insert {
            Lists.Detail.Preference.Record(detailID: detail.id, preference)
        } onConflict: {
            $0.detailID
        } doUpdate: { row, _ in
            row.showCompleted = !row.showCompleted
        }
    }
}

extension Lists.Record {
    /// The one row holding the open detail and the row being edited.
    public static var state: Where<Lists.Record> { Lists.Record.find(1) }

    public var openDetail: Lists.Detail? { detail.flatMap(Lists.Detail.init(id:)) }

    public static func set(detail: Lists.Detail?) -> UpdateOf<Lists.Record> {
        Lists.Record.find(1).update { $0.detail = detail?.id }
    }

    public static func set(editing: Reminder.ID?) -> UpdateOf<Lists.Record> {
        Lists.Record.find(1).update { $0.editing = editing }
    }
}
