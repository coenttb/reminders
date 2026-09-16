import Organizing
import Reminders

extension Reminder.Sample {
    enum Words {}
}

extension Reminder.Sample.Words {
    static let verbs = ["Buy", "Call", "Email", "Fix", "Plan", "Book", "Review", "Renew", "Pay", "Return", "Clean", "Read", "Schedule", "Cancel", "Pick up", "Send", "Write", "Print", "Order", "Check"]
    static let objects = ["groceries", "the dentist", "the plumber", "flights", "the report", "insurance", "rent", "the library books", "the garage", "chapter four", "the invoice", "the subscription", "the kids", "the parcel", "the essay", "the photos", "new tyres", "the smoke alarm", "the passport", "the budget"]
    static let notes = ["Ask about the weekend plans", "Before Friday", "Compare two quotes first", "Milk\nEggs\nApples", "Needs the account number", "Second reminder", "Check the warranty"]
    static let listNames = ["Personal", "Family", "Business", "Errands", "Home", "Travel", "Health", "Finance", "Garden", "Reading", "Projects", "Gifts", "Car", "School", "Music"]
    static let tagNames = ["adulting", "car", "kids", "night", "optional", "social", "someday", "urgent", "weekend", "work", "home", "health", "money", "travel", "gift", "fun", "chores", "calls", "reading", "fitness"]
    static let colors: [Organizing.Color] = [
        .default,
        Organizing.Color(red: 255 / 255, green: 59 / 255, blue: 48 / 255),
        Organizing.Color(red: 255 / 255, green: 149 / 255, blue: 0),
        Organizing.Color(red: 255 / 255, green: 204 / 255, blue: 0),
        Organizing.Color(red: 52 / 255, green: 199 / 255, blue: 89 / 255),
        Organizing.Color(red: 175 / 255, green: 82 / 255, blue: 222 / 255),
        Organizing.Color(red: 162 / 255, green: 132 / 255, blue: 94 / 255),
    ]

    static func list(_ index: Int) -> String {
        let name = listNames[index % listNames.count]
        return index < listNames.count ? name : "\(name) \(index / listNames.count + 1)"
    }

    static func tag(_ index: Int) -> String {
        let name = tagNames[index % tagNames.count]
        return index < tagNames.count ? name : "\(name)\(index / tagNames.count + 1)"
    }

    static func title(_ random: inout Reminder.Sample.Random) -> String {
        "\(verbs[random.next(in: 0..<verbs.count)]) \(objects[random.next(in: 0..<objects.count)])"
    }

    static func note(_ random: inout Reminder.Sample.Random) -> String { notes[random.next(in: 0..<notes.count)] }
}
