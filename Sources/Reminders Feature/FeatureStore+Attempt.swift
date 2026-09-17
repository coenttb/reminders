public import ComposableArchitecture2
import Foundation
import Reminders

extension FeatureStore {
    // A failed effect is reported to the root; cancellation is not a failure.
    func attempt(_ body: () async throws -> Void) async throws {
        do {
            try await body()
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            try self.post(key: Reminders.Feature.Failed.self, value: error.localizedDescription)
        }
    }
}
