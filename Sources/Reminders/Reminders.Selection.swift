public import CasePaths

extension Reminders {
    @CasePathable
    public enum Selection: Hashable, Sendable {
        case filter(Filter)
        case search(Search.Query)
    }
}
