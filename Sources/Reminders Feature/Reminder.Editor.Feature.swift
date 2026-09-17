public import ComposableArchitecture2
public import Dependencies
public import Foundation
public import Reminder
public import Reminders
public import Tagged

extension Reminder.Editor {
    // One row being edited in place. The draft is bound to directly; the parent listing commits it.
    @ComposableArchitecture2.Feature public struct Feature {
        public struct State: Hashable, Sendable {
            public typealias Feature = Reminder.Editor.Feature

            public var draft: Reminder
            public var original: Reminder
            public let place: Reminders.Placement
            public let session: UUID
            public var failure: String?

            public init(draft: Reminder, original: Reminder, place: Reminders.Placement, session: UUID) {
                self.draft = draft
                self.original = original
                self.place = place
                self.session = session
            }

            public init(_ placement: Reminders.Placement, session: UUID) {
                self.init(draft: placement.reminder, original: placement.reminder, place: placement, session: session)
            }

            public var id: Reminder.ID { original.id }

            public var isSaved: Bool { draft == original }
        }

        public enum Action {
            case completeButtonTapped
            case datePresetSelected(Reminder.Editor.Preset?)
            case detailsButtonTapped
            case notesFocused
            case repeatSelected(Calendar.RecurrenceRule.Frequency?)
            case timePresetSelected(Reminder.Editor.Preset.Time?)
            case titleSubmitted
        }

        @Dependency(\.calendar) var calendar
        @Dependency(\.date.now) var now

        public init() {}

        public var body: some ComposableArchitecture2.FeatureProtocol<State, Action> {
            ComposableArchitecture2.Update { state, action in
                switch action {
                case .completeButtonTapped, .detailsButtonTapped, .titleSubmitted:
                    break
                case let .datePresetSelected(preset):
                    state.draft.set(datePreset: preset, at: now, calendar: calendar)
                case .notesFocused:
                    if state.draft.isBlank { state.draft.title = "New Reminder" }
                case let .repeatSelected(frequency):
                    state.draft.repeats = frequency.map { Calendar.RecurrenceRule(calendar: calendar, frequency: $0) }
                case let .timePresetSelected(preset):
                    state.draft.set(timePreset: preset, at: now, calendar: calendar)
                }
            }
        }
    }
}
