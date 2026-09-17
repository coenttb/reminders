import Clocks
import ComposableArchitecture2
import ComposableArchitectureTestSupport
import Dependencies
import DependenciesTestSupport
import Foundation
import Models
import Reminder
import Reminders
import Reminders_Sample
import Reminders_Dependency
import Reminders_Feature
import Reminders_SQL
import Reminders_SQLite
import Sharing
import SQLiteData
import Testing
import Tagged

// A seeded monkey over the whole feature: random actions, then the database's invariants. A failure prints
// the seed and the steps so the run replays.
@Suite(.dependencies {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "UTC")!
    $0.calendar = calendar
    $0.date.now = Date(timeIntervalSince1970: 1_234_567_890)
    $0.uuid = .incrementing
    try $0.bootstrapDatabase(seeding: Reminders.sample(at: Date(timeIntervalSince1970: 1_234_567_890)))
})
struct `Reminder chaos` {
    @Dependency(\.calendar) var calendar
    @Dependency(\.date.now) var now
    @Dependency(\.defaultDatabase) var database

    typealias Store = TestStoreActor<Reminders.Feature>

    static var seeds: [UInt64] {
        let count = ProcessInfo.processInfo.environment["CHAOS_RUNS"].flatMap(Int.init) ?? 3
        return (1...UInt64(count)).map { $0 }
    }

    @Test func `random actions keep the database consistent`() async throws {
        for seed in Self.seeds { try await run(seed: seed) }
    }

    func run(seed: UInt64) async throws {
        try await TestExhaustivity.$current.withValue(.off) {
        var random = Reminders.Sample.Random(seed: seed)
        let clock = TestClock()
        let store = await withDependencies { $0.continuousClock = clock } operation: {
            await Store(initialState: Reminders.Feature.State()) { Reminders.Feature() }
        }
        let steps = ProcessInfo.processInfo.environment["CHAOS_STEPS"].flatMap(Int.init) ?? 150
        var log: [String] = []
        for step in 0..<steps {
            let action = try await pick(store, &random)
            log.append("\(step): \(action)")
            switch action {
            case .clock(let seconds):
                await clock.advance(by: .seconds(seconds))
            case .modifyTitle(let title):
                await store.modify { $0.listing?.editing?.draft.title = title }?.value
            case .modifyNotes(let notes):
                await store.modify { $0.listing?.editing?.draft.notes = notes }?.value
            case .modifyFormTitle(let title):
                await store.modify {
                    if case var .reminder(form) = $0.destination { form.draft.title = title; $0.destination = .reminder(form) }
                }?.value
            case .send(let action, let name):
                let task = await store.send(action)
                if !name.hasPrefix("complete") { await task?.value }
            }
            await Task.yield()
            if step % 25 == 24 { try await check(store, seed: seed, log: log) }
        }
        await clock.advance(by: .seconds(10))
        try await check(store, seed: seed, log: log)
        await store.dismount()
        try await check(store, seed: seed, log: log, dismounted: true)
        }
    }

    enum Step: CustomStringConvertible {
        case clock(Int)
        case modifyTitle(String)
        case modifyNotes(String)
        case modifyFormTitle(String)
        case send(Reminders.Feature.Action, String)

        var description: String {
            switch self {
            case .clock(let s): "clock +\(s)s"
            case .modifyTitle(let t): "title = \(t.debugDescription)"
            case .modifyNotes(let n): "notes = \(n.debugDescription)"
            case .modifyFormTitle(let t): "form title = \(t.debugDescription)"
            case .send(_, let name): name
            }
        }
    }

    static let words = ["Milk", "Call mum", "", " ", "Rye bread", "Fix the sink", "Tax return", "🎉 party", "Ünïcödé", "a"]

    func pick(_ store: Store, _ random: inout Reminders.Sample.Random) async throws -> Step {
        let state = await store.state
        let summary = state.overview.summary
        let lists = summary.lists.map(\.list.id)
        let tags = summary.tags.map(\.tag)
        let rows = state.listing?.page.rows.map(\.id) ?? []
        let word = Self.words.randomElement(using: &random)!
        switch state.destination {
        case .reminder:
            switch Int.random(in: 0..<5, using: &random) {
            case 0: return .send(.destination(.reminder(.cancelButtonTapped)), "form cancel")
            case 1: return .send(.destination(.reminder(.saveButtonTapped)), "form save")
            case 2: return .modifyFormTitle(word)
            case 3: return .send(.destination(.reminder(.tagAdded(word))), "form tag \(word)")
            default: return .send(.destination(.reminder(.flagToggled)), "form flag")
            }
        case .list:
            return .send(.destination(.list(.cancelButtonTapped)), "list form cancel")
        case nil:
            break
        }
        guard let listing = state.listing else {
            switch Int.random(in: 0..<5, using: &random) {
            case 0 where !lists.isEmpty: return .send(.overview(.listTapped(lists.randomElement(using: &random)!)), "open list")
            case 1 where !tags.isEmpty: return .send(.overview(.tagTapped(tags.randomElement(using: &random)!)), "open tag")
            case 2: return .send(.newReminderButtonTapped, "new reminder sheet")
            case 3: return .send(.appBackgrounded, "background")
            default:
                let filter = [Reminders.Filter.today, .scheduled, .all, .flagged, .completed].randomElement(using: &random)!
                return .send(.overview(.filterTapped(filter)), "open \(filter)")
            }
        }
        if listing.editing != nil, Bool.random(using: &random) {
            switch Int.random(in: 0..<7, using: &random) {
            case 0: return .modifyTitle(word)
            case 1: return .modifyNotes(word)
            case 2: return .send(.listing(.editing(.titleSubmitted)), "return")
            case 3: return .send(.listing(.doneButtonTapped), "done")
            case 4: return .send(.listing(.editing(.detailsButtonTapped)), "details from row")
            case 5: return .send(.listing(.editing(.completeButtonTapped)), "complete from row")
            default: return .send(.listing(.backgroundTapped), "background tap")
            }
        }
        switch Int.random(in: 0..<16, using: &random) {
        case 0: return .send(.listing(.newReminderButtonTapped), "new row")
        case 1 where !rows.isEmpty: return .send(.listing(.reminderTapped(rows.randomElement(using: &random)!)), "tap row")
        case 2 where !rows.isEmpty: return .send(.listing(.reminderCompleteButtonTapped(rows.randomElement(using: &random)!)), "complete row")
        case 3 where !rows.isEmpty: return .send(.listing(.reminderDeleted(rows.randomElement(using: &random)!)), "delete row")
        case 4 where !rows.isEmpty: return .send(.listing(.reminderDetailsButtonTapped(rows.randomElement(using: &random)!)), "details row")
        case 5: return .send(.listing(.orderingSelected([Reminders.Ordering.manual, .dueDate, .title, .priority].randomElement(using: &random)!)), "ordering")
        case 6: return .send(.listing(.showCompletedButtonTapped), "show completed")
        case 7 where rows.count > 1:
            let from = Int.random(in: 0..<rows.count, using: &random)
            let to = Int.random(in: 0...rows.count, using: &random)
            return .send(.listing(.remindersMoved(IndexSet(integer: from), to)), "move \(from)->\(to)")
        case 8: return .send(.listing(.clearCompletedButtonTapped), "clear completed")
        case 9: return .clock(Int.random(in: 0...6, using: &random))
        case 10: return .send(.listing(.backgroundTapped), "background tap")
        case 11: return .send(.appBackgrounded, "background")
        case 12: return .send(.appActivated, "activate")
        case 13: return .send(.listing(.endReached), "end reached")
        case 14 where listing.list != nil && Int.random(in: 0..<4, using: &random) == 0: return .send(.listing(.listDeleteButtonTapped), "delete list")
        default: return .clock(1)
        }
    }

    func check(_ store: Store, seed: UInt64, log: [String], dismounted: Bool = false) async throws {
        let state = await store.state
        let editing = dismounted ? nil : state.listing?.editing
        let replay = "seed \(seed)\n" + log.joined(separator: "\n")
        #expect(state.failure == nil, "failure \(state.failure ?? "")\n\(replay)")
        try await database.read { db in
            let blank = try Reminder.Record.where { $0.title.eq("") }.select(\.id).fetchAll(db)
            #expect(Set(blank).subtracting(editing.map { [$0.id] } ?? []).isEmpty, "blank rows \(blank)\n\(replay)")
            let positions = try Reminder.Record.select(\.position).fetchAll(db)
            #expect(Set(positions).count == positions.count, "duplicate positions\n\(replay)")
            let lists = try Models.List<Reminder>.Record.all.fetchCount(db)
            #expect(lists >= 1, "no list\n\(replay)")
            let orphans = try #sql("SELECT count(*) FROM remindersTags t WHERE NOT EXISTS (SELECT 1 FROM tags WHERE title = t.tagID) OR NOT EXISTS (SELECT 1 FROM reminders WHERE id = t.reminderID)", as: Int.self).fetchOne(db)
            #expect(orphans == 0, "orphan taggings\n\(replay)")
            let twins = try #sql("SELECT count(*) - count(DISTINCT lower(title)) FROM tags", as: Int.self).fetchOne(db)
            #expect(twins == 0, "twin tags\n\(replay)")
            if let editing {
                #expect(try Reminder.Record.find(editing.id).fetchCount(db) == 1, "editing a row that is gone\n\(replay)")
            }
        }
        @Shared(.appStorage(Reminders.Listing.Feature.editingKey)) var restored: String?
        #expect(restored == editing?.id.rawValue.uuidString, "app storage \(restored ?? "nil") vs \(editing?.id.rawValue.uuidString ?? "nil")\n\(replay)")
    }
}
