public import Organizing
public import Reminders
public import Tagged

extension List<Reminder>.Record.Draft {
    public static func create(id: List<Reminder>.ID? = nil, title: String = "", color: Color.Hex = Color.Hex(Color.default), position: Int = 0) -> Self {
        Self(id: id, title: title, color: color, position: position)
    }
}
