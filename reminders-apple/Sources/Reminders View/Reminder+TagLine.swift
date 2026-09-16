import Models
public import Reminder

extension Reminder {
    public var tagLine: String {
        tags.sorted().map { Tag<Reminder>.hashtag($0) }.joined(separator: " ")
    }
}
