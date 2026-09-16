public import Organizing
public import Reminders
public import StructuredQueries
public import Tagged

extension QueryExpression where QueryValue == Tag<Reminder>.ID {
    package var text: SQLQueryExpression<String> { SQLQueryExpression("\(self)") }
}
