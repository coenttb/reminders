extension Collection where Index == Int {
    func chunks(of size: Int) -> [SubSequence] {
        stride(from: startIndex, to: endIndex, by: size).map { self[$0..<Swift.min($0 + size, endIndex)] }
    }
}
