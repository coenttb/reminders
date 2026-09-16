public import Organizing

extension Color {
    public struct Hex: RawRepresentable, Hashable, Sendable {
        public var rawValue: Int64

        public init(rawValue: Int64) {
            self.rawValue = rawValue
        }
    }
}
