public import Organizing
public import SQLiteData
import Standard_Library_Extensions

extension Color {
    /// A color as the integer `0xRRGGBB` the lists table stores.
    public struct Hex: RawRepresentable, Hashable, Sendable, QueryBindable {
        public var rawValue: Int64

        public init(rawValue: Int64) {
            self.rawValue = rawValue
        }
    }
}

extension Color.Hex {
    public init(_ color: Color) {
        func byte(_ component: Double) -> Int64 { Int64((component.clamped(to: 0...1) * 0xFF).rounded()) }
        self.init(rawValue: byte(color.red) << 16 | byte(color.green) << 8 | byte(color.blue))
    }

    public var color: Color {
        Color(
            red: Double((rawValue >> 16) & 0xFF) / 0xFF,
            green: Double((rawValue >> 8) & 0xFF) / 0xFF,
            blue: Double(rawValue & 0xFF) / 0xFF
        )
    }
}
