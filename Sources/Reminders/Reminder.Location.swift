extension Reminder {
    /// The two fixed locations the inline row offers; a custom place is not modelled.
    public enum Location: String, CaseIterable, Hashable, Sendable {
        case gettingInCar
        case gettingOutOfCar
    }
}
