# Implementation review

## Policy ownership

```swift
@Editor
extension Reminders {
    public var editing: some Editor {
        Editing(
            create: create,
            update: update,
            delete: delete,
            draft: \.draft,
            blank: .discardNewDeleteExisting(\.isBlank),
            commit: .dismiss,
            discard: .delete
        )
    }
}
```

The page only selects `Listing(self, rows: \.rows, editing: \Reminders.editing)`.
Views use `Editing.Rows(..., editor: Reminder.View.Row.Editor.init)` and
`Submit("Done", store: store, allowing: !store.isBlank)`.

`commit: .manual` disables automatic saving on dismissal; explicit commit remains
available. `discard: .manual` disables automatic removal on matching record deletion.
Explicit parent discard still terminates its owned sessions.

## Names

| Previous | Selected |
| --- | --- |
| DraftProjection / EditingFeature / @EditingPolicy | Lens / Editor / @Editor |
| ListingProjection | Rows |
| Editing.BlankDraftPolicy | Editing.Blank |
| EditingLifetime | Editing.State.Lifetime |
| InlineEditing / RequestButton | Editing.Rows / Submit |
| TaskFailure / DiscardablePresentation | Tasks.Failure / Discardable |
| ViewStore / ViewBindings / PresentationBinding | Stored / Bindings / Presentation |
| InterfaceContext / WithInterface | Context / Inherited |
| FeatureSelection / FeatureComposition | Selection / Composition |
| InterfaceStoreProjection / InterfaceCompositionState | Scoping / Composite |
| InterfaceFeature / InterfaceCalls | Calling / Routed |
| CallPaths / CallPath | Paths / Paths.Case |
| InterfaceFactory / InterfaceConstructible | Factory / Constructible |
| InterfacePrimary / InterfaceMember / InterfaceOption | Interface.Primary / Interface.Member / Interface.Option |
| TestDependency / UnimplementedInterface / TestStreamFallback | Unimplemented / Unimplemented / Unimplemented.Streams |

Macro implementations use short role names inside their plugin module. Generated
witnesses are `_Editing` and `_Rows`. External library names, such as FeatureProtocol
and StoreTaskID, remain unchanged. No compatibility aliases retain the replaced
APIs; this is a source-breaking change to the experimental bridge.

`Failure` alone collides with the canonical domain error type. `Requesting.Button`
is shadowed by the macro-derived Requesting function in nested request views.
`Tasks.Failure` and `Submit` avoid both collisions without module-qualified UI syntax.

## Complexity removed

- Listing's modifier wrapper, event types, and independent lifecycle flags duplicated
  the editing policy. Standalone editing and Listing now read the same selection.
- Obsolete EditingRows coupled presentation to querying and duplicated the current
  adapter. It had no remaining consumers and was removed.
- Ignored-update-error overloads survived after Reminders stopped using them. Removing
  them eliminates duplicate macro emissions and adapters. All operation errors now
  propagate. Deliberate domain error translation belongs in the selected operation.
- The explicit-owner Listing convenience delegates to the canonical initializer.

## Remaining complexity

| Area | Why it remains / next simplification boundary |
| --- | --- |
| Feature body inspection | Deriving a stable state product requires an explicit selection grammar. Arbitrary Swift control flow cannot be treated as a fixed product. |
| Composition emission | The largest generator: it maps each selected child into State, Action, store projections, and binding projections. It already attaches TCA @Feature, which supplies observation/scopes. Explicit state conformances and projection shapes remain bridge code. A shared child descriptor already exists; further factoring should reduce repeated mapping rather than duplicate TCA. |
| Child key-path dispatch and AnyFeature | Connects heterogeneous scopes to canonical domain key paths. Removing runtime selection requires different source coordinates or manual type witnesses. Keep domain key paths rather than introducing Structural machinery at call sites. |
| Canonical call routing | Distinguishes the same operation at different mounted stores. Flattening it risks assigning errors/cancellation to the wrong store. Calls/Routed preserve that distinction. |
| Shared discard lifetime | Captured dismount snapshots must see a subsequent discard. Removing the reference revives the deletion/commit race. It does not undo an already-started write. |
| Listing Session interpreter | Keeps commit failures on the page's writes task after the editor disappears. Directly mounting Editing loses that ownership. |
| Conditional Discardable projection | Propagates termination through children without making unrelated states conform or creating a second session tree. |
| Store/binding adapters | Preserve ownership across required and presented children; views never manufacture another store. |
| Factory overloads | Compile-time result-shape selection avoids casts/fabricated values and preserves typed errors and noncopyable output. Arbitrary results require explicit test implementations. |
| SQL records | Still duplicate domain fields. A legal composition with the table macro remains unresolved under the extension constraints. |

The largest further opportunity is reducing the repeated child-to-state/store/binding
mapping while preserving store-route identity. The compiler restriction specifically
blocks relying on an extension macro inside another macro’s extension output, or
extending a type other than the attached type; it does not prove that all further
composition simplifications are impossible. Shorter names alone do not solve this.

## Validation

The exact `reminders-architecture.xcworkspace` macOS test run passed: 143 tests
reported, zero unexpected failures, one intentional known-issue assertion for
unimplemented dependency reporting. This includes manual-commit behavior and
uniform create/update/delete error propagation, alongside the existing deletion
lifecycle, store-routing, macro boundary, and binding tests.

The final generic iOS Simulator build also passed using the same workspace,
including the final Interface namespace changes.
