public import Models
public import SwiftUI

extension Models.Color {
    public init(_ color: SwiftUI.Color) {
        let resolved = color.resolve(in: EnvironmentValues())
        self.init(red: Double(resolved.red), green: Double(resolved.green), blue: Double(resolved.blue))
    }
}
