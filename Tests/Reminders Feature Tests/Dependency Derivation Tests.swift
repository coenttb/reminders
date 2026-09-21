import Reminders
import Reminders_Dependency
import Testing

@Test func explicitUnimplementedStreamReportsItsCallAndTerminates() async throws {
    var stream: Reminders.Read.Output?
    withKnownIssue {
        stream = Reminders.testValue.read()
    }
    var iterator = try #require(stream).makeAsyncIterator()
    #expect(try await iterator.next() == nil)
}
