extension Color {
    public init(_ hex: Color.Hex) {
        self.init(
            red: Double((hex.rawValue >> 16) & 0xFF) / 0xFF,
            green: Double((hex.rawValue >> 8) & 0xFF) / 0xFF,
            blue: Double(hex.rawValue & 0xFF) / 0xFF
        )
    }
}
