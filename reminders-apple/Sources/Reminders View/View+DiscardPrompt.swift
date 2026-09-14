public import SwiftUI

extension View {
    /// The question a sheet asks before an edited draft is thrown away, as a popover
    /// growing out of the button it is attached to: the question, then one
    /// destructive Discard Changes; tapping elsewhere keeps editing.
    public func discardPrompt(_ title: String, isPresented: Binding<Bool>, discard: @escaping () -> Void) -> some View {
        popover(isPresented: isPresented, arrowEdge: .top) {
            VStack(spacing: 16) {
                Text(title)
                    .font(.callout)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                Button(role: .destructive) {
                    isPresented.wrappedValue = false
                    discard()
                } label: {
                    Text("Discard Changes").frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(.secondary)
                .foregroundStyle(.red)
                .controlSize(.large)
            }
            .padding(20)
            .frame(width: 240)
            .presentationCompactAdaptation(.popover)
        }
    }
}
