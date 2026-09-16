public import Organizing
import Standard_Library_Extensions

extension Color.Hex {
    public init(_ color: Color) {
        func byte(_ component: Double) -> Int64 { Int64((component.clamped(to: 0...1) * 0xFF).rounded()) }
        self.init(rawValue: byte(color.red) << 16 | byte(color.green) << 8 | byte(color.blue))
    }
}
