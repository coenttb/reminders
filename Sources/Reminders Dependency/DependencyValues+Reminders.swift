public import Dependencies
import Interface_Dependencies
public import Reminders

extension DependencyValues {
    public var reminders: Reminders {
        get { self[Reminders.self] }
        set { self[Reminders.self] = newValue }
    }
}

extension Reminders: TestDependencyKey {
    public static let testValue = Reminders(
        create: .init { _ in
            try Unimplemented.value(output: Create.Output.self, failure: Create.Failure.self, operation: "Reminders.Create")
        },
        read: .init(
            { _ in
                Unimplemented.value(output: Read.Output.self, failure: Read.Failure.self, operation: "Reminders.Read")
            },
            id: { _ in
                try Unimplemented.value(output: Read.Id.Output.self, failure: Read.Id.Failure.self, operation: "Reminders.Read.Id")
            },
            page: .init { _ in
                Unimplemented.value(output: Read.Page.Output.self, failure: Read.Page.Failure.self, operation: "Reminders.Read.Page")
            }
        ),
        update: .init(
            { _ in
                try Unimplemented.value(output: Update.Output.self, failure: Update.Failure.self, operation: "Reminders.Update")
            },
            complete: .init { _ in
                try Unimplemented.value(output: Update.Complete.Output.self, failure: Update.Complete.Failure.self, operation: "Reminders.Update.Complete")
            }
        ),
        delete: .init { _ in
            try Unimplemented.value(output: Delete.Output.self, failure: Delete.Failure.self, operation: "Reminders.Delete")
        },
        lists: .init(
            create: .init { _ in
                try Unimplemented.value(output: Lists.Create.Output.self, failure: Lists.Create.Failure.self, operation: "Reminders.Lists.Create")
            },
            delete: .init { _ in
                try Unimplemented.value(output: Lists.Delete.Output.self, failure: Lists.Delete.Failure.self, operation: "Reminders.Lists.Delete")
            }
        )
    )
}
