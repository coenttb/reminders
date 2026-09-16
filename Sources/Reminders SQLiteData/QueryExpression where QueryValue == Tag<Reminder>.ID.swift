import Organizing
import Reminders
import SQLiteData
import Tagged

extension QueryExpression where QueryValue == Tag<Reminder>.ID {
    var text: SQLQueryExpression<String> { SQLQueryExpression("\(self)") }
}
