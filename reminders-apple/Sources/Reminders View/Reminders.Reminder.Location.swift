public import Reminders

extension Reminders.Reminder.Location {
    public var title: String {
        switch self {
        case .gettingInCar: "Getting in Car"
        case .gettingOutOfCar: "Getting out of Car"
        }
    }
}
