public import Interface_Macro
public import List
public import Reminder

extension Reminders.Lists {
    // There is always a list: deleting the last one installs the default list.
    @Interface
    public struct Delete: Delete.Interface {
        @Operations
        public protocol Interface {
            func callAsFunction(_ id: List<Reminder>.ID) async throws
        }
    }
}
