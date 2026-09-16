public import Organizing
public import SwiftUI

extension SwiftUI.Color {
    public init(_ color: Organizing.Color) {
        self.init(red: color.red, green: color.green, blue: color.blue)
    }
}
