public import ComposableArchitecture2
public import Dependencies
public import Models
public import Reminder
public import Reminders
import Reminders_Dependency
import Standard_Library_Extensions
public import Tagged
import Foundation

extension Reminder.Form {
    @ComposableArchitecture2.Feature public struct Feature {
        public struct State: Sendable {
            public typealias Feature = Reminder.Form.Feature

            public var draft: Reminder
            public let original: Reminder?
            // The whole form, or the Date & Time rows alone (the Custom sheet from a row's chips).
            public let part: Part
            public var failure: String?
            public var isSaving = false
            // Pending tag intents: the tasks of one action replace each other, so a restarted task works
            // through what the state still holds.
            public var addingTags: [String] = []
            public var deletingTags: [Tag<Reminder>] = []
            public var renamingTags: [(Tag<Reminder>, String)] = []

            public init(draft: Reminder, original: Reminder?, part: Part = .all) {
                self.draft = draft
                self.original = original
                self.part = part
            }

            public enum Part: Hashable, Sendable { case all, dates }

            public var isNew: Bool { original == nil }

            public var isDirty: Bool { original.map { draft != $0 } ?? true }

            public mutating func fail(_ reason: String) {
                failure = reason
                isSaving = false
            }
        }

        public enum Action {
            case cancelButtonTapped
            case datePresetSelected(Reminder.Editor.Preset)
            case flagToggled
            case listSelected(Models.List<Reminder>.ID)
            case saveButtonTapped
            case tagAdded(String)
            case tagDeleted(Tag<Reminder>)
            case tagRenamed(Tag<Reminder>, String)
            case tagToggled(Tag<Reminder>)
        }

        @Dependency(\.calendar) var calendar
        @Dependency(\.date.now) var now
        @Dependency(\.reminders) var reminders

        public init() {}

        public var body: some ComposableArchitecture2.FeatureProtocol<State, Action> {
            ComposableArchitecture2.Update { state, action in
                switch action {
                case .cancelButtonTapped:
                    break
                case let .datePresetSelected(preset):
                    state.draft.set(datePreset: preset, at: now, calendar: calendar)
                case .flagToggled:
                    state.draft.flagged.toggle()
                case let .listSelected(list):
                    state.draft.list = list
                case .saveButtonTapped:
                    guard !state.draft.isBlank, !state.isSaving else { break }
                    state.isSaving = true
                    let (draft, isNew) = (state.draft, state.isNew)
                    store.addTask {
                        try await attempt {
                            do {
                                _ = try await isNew ? reminders.create(draft, below: nil) : reminders.update(draft)
                                try store.dismiss()
                            } catch Reminders.Update.Error.notFound {
                                try store.modify { $0.fail("This reminder was deleted.") }
                            }
                        }
                    }
                case let .tagAdded(title):
                    state.addingTags.append(title)
                    store.addTask {
                        while let title = store.addingTags.first {
                            try await attempt {
                                let tag = try await create(tag: title)
                                try store.modify {
                                    if let tag { $0.draft.tags.insert(tag) }
                                    $0.failure = nil
                                }
                            }
                            try store.modify { $0.addingTags.removeFirst() }
                        }
                    }
                case let .tagDeleted(id):
                    state.deletingTags.append(id)
                    store.addTask {
                        while let id = store.deletingTags.first {
                            try await attempt {
                                try await reminders.tags.delete(id)
                                try store.modify {
                                    $0.draft.tags.remove(id)
                                    $0.failure = nil
                                }
                                try store.post(key: Reminders.Feature.TagDeleted.self, value: id)
                            }
                            try store.modify { $0.deletingTags.removeFirst() }
                        }
                    }
                case let .tagToggled(tag):
                    state.draft.tags.toggle(tag)
                case let .tagRenamed(id, title):
                    state.renamingTags.append((id, title))
                    store.addTask {
                        while let (id, title) = store.renamingTags.first {
                            try await attempt {
                                guard let renamed = try await rename(tag: id, to: title) else { return }
                                try store.modify {
                                    $0.draft.tags.replace(id, with: renamed)
                                    $0.failure = nil
                                }
                            }
                            try store.modify { $0.renamingTags.removeFirst() }
                        }
                    }
                }
            }
        }
    }
}

extension Reminder.Form.Feature {
    private func create(tag title: String) async throws -> Tag<Reminder>? {
        do {
            return try await reminders.tags.create(title)
        } catch Reminders.Tags.Error.blank {
            return nil
        }
    }

    private func rename(tag: Tag<Reminder>, to title: String) async throws -> Tag<Reminder>? {
        do {
            return try await reminders.tags.rename(tag, to: title)
        } catch Reminders.Tags.Error.blank, Reminders.Tags.Error.notFound {
            return nil
        }
    }

    private func attempt(_ body: () async throws -> Void) async throws {
        do {
            try await body()
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            try store.modify { $0.fail(error.localizedDescription) }
        }
    }
}
