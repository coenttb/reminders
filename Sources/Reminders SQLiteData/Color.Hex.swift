public import Organizing
public import SQLiteData
import Standard_Library_Extensions

extension Color {
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
}
