import Standard_Library_Extensions
import Testing

private enum StreamFailure: Error { case stopped }

@Test func streamAdaptationPreservesValuesAndFailure() async throws {
    let source = AsyncThrowingStream<Int, any Error> { continuation in
        continuation.yield(1)
        continuation.yield(2)
        continuation.finish(throwing: StreamFailure.stopped)
    }
    var iterator = source.eraseToThrowingStream().makeAsyncIterator()
    #expect(try await iterator.next() == 1)
    #expect(try await iterator.next() == 2)
    await #expect(throws: StreamFailure.stopped) { try await iterator.next() }
}

@Test(.timeLimit(.minutes(1)))
func cancellingAdaptedStreamCancelsItsUpstreamObservation() async throws {
    let (termination, signal) = AsyncStream<Void>.makeStream()
    let source = AsyncStream<Int> { continuation in
        continuation.onTermination = { reason in
            if case .cancelled = reason { signal.yield(()) }
            signal.finish()
        }
    }
    let stream = source.eraseToThrowingStream()
    let consumer = Task { for try await _ in stream {} }
    consumer.cancel()
    _ = try? await consumer.value
    var events = termination.makeAsyncIterator()
    #expect(await events.next() != nil)
}
