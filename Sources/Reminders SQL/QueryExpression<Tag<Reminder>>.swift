import Models
import Reminder
package import StructuredQueries

extension QueryExpression<Tag<Reminder>> {
    package var text: SQLQueryExpression<String> { SQLQueryExpression("\(self)") }
}
