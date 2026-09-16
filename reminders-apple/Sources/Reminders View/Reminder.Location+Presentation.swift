public import Reminder

extension Reminder.Location {
    public var title: String {
        switch self {
        case .gettingInCar: "Getting in Car"
        case .gettingOutOfCar: "Getting out of Car"
        }
    }
}
