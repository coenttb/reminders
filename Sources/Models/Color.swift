public struct Color: Hashable, Sendable {
    public var red: Double
    public var green: Double
    public var blue: Double

    public init(red: Double, green: Double, blue: Double) {
        self.red = red
        self.green = green
        self.blue = blue
    }
}

extension Color {
    public static let `default` = Color(red: 74 / 255, green: 153 / 255, blue: 239 / 255)
}
