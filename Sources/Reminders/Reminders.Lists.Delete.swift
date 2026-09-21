public import Interface_Macro
public import List
public import Reminder

extension Reminders.Lists {
    // There is always a list: deleting the last one installs the default list.
    @Interface(inputConformances: ["Swift.Equatable", "Swift.Sendable"])
    public struct Delete: Delete.Interface, Sendable {
        public protocol Interface {
            func callAsFunction(_ id: List<Reminder>.ID) async throws
        }
    }
}
