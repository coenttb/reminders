import Organizing
import Reminder
package import StructuredQueries
import Tagged

extension QueryExpression<Tag<Reminder>.ID> {
    package var text: SQLQueryExpression<String> { SQLQueryExpression("\(self)") }
}
