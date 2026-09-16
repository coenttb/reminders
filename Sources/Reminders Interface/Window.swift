public struct Window<Key: Hashable & Sendable>: Hashable, Sendable {
    public var key: Key?
    public var rows: Int?
    public let step: Int
    public let margin: Int

    public init(key: Key?, rows: Int?, step: Int, margin: Int) {
        self.key = key
        self.rows = rows
        self.step = step
        self.margin = margin
    }

    public init(step: Int, margin: Int) {
        self.init(key: nil, rows: step, step: step, margin: margin)
    }
}

extension Window {
    public func limit(for key: Key) -> Int? {
        self.key == key ? rows : step
    }

    public mutating func widen(for key: Key, shown: Int, total: Int) {
        guard shown < total, let limit = limit(for: key) else { return }
        self.key = key
        rows = limit + step
    }

    public mutating func extend(for key: Key, by count: Int) {
        guard let limit = limit(for: key) else { return }
        self.key = key
        rows = limit + count
    }

    public mutating func open(for key: Key) {
        self.key = key
        rows = nil
    }

    public func nearsEnd(_ index: Int, of shown: Int, total: Int) -> Bool {
        shown < total && index >= shown - margin
    }
}
