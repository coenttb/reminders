/// How many rows of a long list are read: one step at a time, widened near the end, and
/// whole for the key that is being edited.
public struct Window<Key: Hashable & Sendable>: Hashable, Sendable {
    public var key: Key?
    public var rows: Int?

    public init(key: Key? = nil, rows: Int? = Self.step) {
        self.key = key
        self.rows = rows
    }
}

extension Window {
    public static var step: Int { 300 }
    public static var margin: Int { 60 }

    public func limit(for key: Key) -> Int? {
        self.key == key ? rows : Self.step
    }

    public mutating func widen(for key: Key, shown: Int, total: Int) {
        guard shown < total, let limit = limit(for: key) else { return }
        self.key = key
        rows = limit + Self.step
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

    public static func nearsEnd(_ index: Int, of shown: Int, total: Int) -> Bool {
        shown < total && index >= shown - margin
    }
}
