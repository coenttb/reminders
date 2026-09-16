public import Models
public import SwiftUI

extension SwiftUI.Color {
    public init(_ color: Models.Color) {
        self.init(red: color.red, green: color.green, blue: color.blue)
    }
}
