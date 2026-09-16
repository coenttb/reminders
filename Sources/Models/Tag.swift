public struct Tag<Element>: RawRepresentable, Hashable, Sendable {
    public var rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }
}

extension Tag: Comparable {
    public static func < (lhs: Self, rhs: Self) -> Bool { lhs.rawValue < rhs.rawValue }
}

extension Tag: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self.init(rawValue: value)
    }
}

extension Tag: CustomStringConvertible {
    public var description: String { rawValue }
}

extension Tag: Identifiable {
    public var id: Self { self }
}
