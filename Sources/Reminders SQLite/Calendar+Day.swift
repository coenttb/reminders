import Foundation

extension Calendar {
    func day(containing date: Date) -> Range<Date> {
        let start = startOfDay(for: date)
        return start..<(self.date(byAdding: .day, value: 1, to: start) ?? start.addingTimeInterval(86_400))
    }
}
