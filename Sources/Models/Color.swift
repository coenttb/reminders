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
    // The stock app's "Blue": the system blue.
    public static let `default` = Color(red: 0, green: 122 / 255, blue: 255 / 255)
}
