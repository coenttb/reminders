#if DEBUG
import ComposableArchitecture2
import Reminders
import Reminders_Sample
import Reminders_View
import SwiftUI

extension Reminders.Sample {
    struct Menu {
        @Bindable private var store: StoreOf<Reminders.Sample.Feature>

        init(store: StoreOf<Reminders.Sample.Feature>) {
            self.store = store
        }
    }
}

extension Reminders.Sample.Menu: SwiftUI::View {
    var body: some SwiftUI::View {
        SwiftUI.Menu {
            Button("Reference sample", systemImage: "leaf") { store.send(.seedButtonTapped) }
            Section("Fixed seed") {
                ForEach([Reminders.Sample.Scale.medium, .large, .extreme], id: \.self) { scale in
                    Button(scale.title) { store.send(.seedGenerated(scale, seed: 1)) }
                }
            }
            Section("Random seed") {
                ForEach([Reminders.Sample.Scale.medium, .large, .extreme], id: \.self) { scale in
                    Button(scale.title) { store.send(.seedGenerated(scale, seed: nil)) }
                }
            }
            if let last = store.lastSeed {
                Button("Replay \(last.description)", systemImage: "arrow.counterclockwise") {
                    store.send(.seedGenerated(last.scale, seed: last.value))
                }
            }
            Divider()
            Button("Delete everything", systemImage: "trash", role: .destructive) { store.send(.deleteEverythingButtonTapped) }
        } label: {
            if store.isSeeding {
                ProgressView()
            } else {
                Label("Seed data", systemImage: "leaf")
            }
        }
        .disabled(store.isSeeding)
    }
}
#endif
