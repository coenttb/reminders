public import Interface_Macro
public import Models

extension Reminders {
    @Interface
    public struct Preferences: Preferences.`Protocol` {
        public protocol `Protocol` {
            func update(_ request: Update.Request) throws
        }
    }
}

extension Reminders.Preferences: @unchecked Sendable {}
