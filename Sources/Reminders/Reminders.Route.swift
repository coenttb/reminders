public import CasePaths

extension Reminders {
    @CasePathable
    public enum Route: Hashable, Sendable {
        case overview
        case filter(Filter)
        case search(Search.Query)
    }
}
