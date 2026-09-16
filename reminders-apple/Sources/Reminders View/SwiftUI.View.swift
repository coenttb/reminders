public import SwiftUI

extension SwiftUI.View {
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
