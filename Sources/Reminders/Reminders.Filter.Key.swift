public import Foundation
public import Models
public import Reminder
import Tagged

extension Reminders.Filter {
    public struct Key: RawRepresentable, Hashable, Sendable {
        public var rawValue: String

        public init(rawValue: String) {
            self.rawValue = rawValue
        }
    }
}

extension Reminders.Filter.Key {
    static let separator: Character = "\u{1F}"

    public init(_ filter: Reminders.Filter) {
        rawValue = switch filter {
        case .all: "all"
        case .completed: "completed"
        case .flagged: "flagged"
        case .scheduled: "scheduled"
        case .today: "today"
        case let .list(id): "list_\(id.rawValue.uuidString)"
        case let .tags(tags): "tags_" + tags.sorted().map(\.rawValue).joined(separator: String(Self.separator))
        }
    }
}

extension Reminders.Filter {
    public init?(key: Reminders.Filter.Key) {
        switch key.rawValue {
        case "all": self = .all
        case "completed": self = .completed
        case "flagged": self = .flagged
        case "scheduled": self = .scheduled
        case "today": self = .today
        case let raw where raw.hasPrefix("list_"):
            guard let uuid = UUID(uuidString: String(raw.dropFirst("list_".count))) else { return nil }
            self = .list(Models.List<Reminder>.ID(uuid))
        case let raw where raw.hasPrefix("tags_"):
            let titles = raw.dropFirst("tags_".count).split(separator: Key.separator)
            self = .tags(Set(titles.map { Tag<Reminder>(rawValue: String($0)) }))
        default:
            return nil
        }
    }
}
