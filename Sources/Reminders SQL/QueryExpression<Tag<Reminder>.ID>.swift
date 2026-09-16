package import Organizing
package import Reminders
package import StructuredQueries
package import Tagged

extension QueryExpression<Tag<Reminder>.ID> {
    package var text: SQLQueryExpression<String> { SQLQueryExpression("\(self)") }
}
