public import Organizing

extension Color {
    /// A colour packed as `0xRRGGBB`, the form a row stores.
    public struct Hex: RawRepresentable, Hashable, Sendable {
        public var rawValue: Int64

        public init(rawValue: Int64) {
            self.rawValue = rawValue
        }
    }
}
