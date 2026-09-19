# Aspirational Reminders feature syntax

The files in `Sources/Reminders Feature` are a design sketch, not a compiling refactor. The checkpoint before this sketch is `f8a468f`. No bridge or macro implementation is changed here. `@Feature` and the composition APIs below describe the proposed end state, not the capabilities of the current TCA macro. Builds and tests would not validate this sketch.

The design keeps domain operations and values authoritative. Feature interpretation derives store representation, routing, observation, and task ownership. It does not infer application policy from a type or member name.

## File-by-file inventory

| File | Machinery in the checkpoint | Proposed declaration and remaining choice |
| --- | --- | --- |
| `Reminders+Feature.swift` | `Structure` descriptors, required-child metadata, `Call.self`, split macro/conformance extensions, explicit `composition`, two action routes, synchronous state mutation | Compose `Child(\.read)` and `Child(\.lists)`. State and action products/sums follow those selections. Declare the rule that deleting a list dismisses the matching page before execution. |
| `Reminders.Read+Feature.swift` | `Read.Run`, `Structure.page`, generated composition selection | `Observing(self)` selects the unique stream-returning operation; `Presenting(\.page)` selects an optional child lifetime. The synchronous read-by-ID overload remains callable without becoming a second observation. |
| `Reminders.Lists+Feature.swift` | `Structure.create`, `Call.self`, macro composition metadata | `Presenting(\.create)` chooses the form lifetime. Other operations remain callable through the interface. |
| `Reminders.Lists.Create+Feature.swift` | Explicit `State` and `Action` aliases, repeated generic `Run` argument | `Requesting(self)` interprets the operation as a request form. Arguments, output, errors, and canonical call derive from the interface. |
| `Reminders.Read.Page+Feature.swift` | `Listing<Run, Call>`, state/action aliases, `WithInterface` closure, passing the same ancestor twice | `Listing(self, rows: \.rows, commands: Reminders.self, editing: \.editing, deleting: \.delete?.id)`. Explicit projections express relationships; the bridge supplies operation symbols and resolves the actual ancestor instance. |
| `Reminders.Update+Feature.swift` | `Editing<Reminder>.State`, `Action = Never`, ancestor lookup closure | `Editing(in: Reminders.self, \.editing)` reuses the root editing policy. The operation called update does not inherently imply the complete editing workflow: that interpretation remains explicit. |
| `Reminders+Editing.swift` | Repeated bridge qualification, record generic argument, `callAsFunction` adaptation, erased-error cast | `Editing(create: create, update: update, delete: delete, draft: \.draft, …)` uses typed operation values. Creation/update/deletion roles, draft lens, blank handling, and ignored failure remain explicit domain choices. |
| `Reminder+EditableRecord.swift` | Empty bridge marker conformance | No declaration. `Editing` consumes the selected writable draft lens and existing identity. It must not guess which fields form a draft. |
| `Reminders.Read.Page.Value+ListingValue.swift` | Empty bridge marker conformance tying a value to a property name | No declaration. `Listing` consumes the selected rows projection. It must not guess which collection is the listing. |
| `Reminders+CasePathable.swift` | Three consumer-side conformances adapting canonical calls to another optics protocol | No declaration. Consume Interface's canonical call optics directly. If a TCA boundary absolutely requires a nominal conformance, that requirement must be addressed at the call declaration or at the boundary, not hidden in a duplicate action enum. |
| `Reminders.Read.Page.State+List.swift` → `Reminders.Read.Filter+List.swift` | Extension of generic `Listing.State`, `Symbol` and `Call` constraints, `contents.request` traversal | Define `list` on the existing domain filter. The case analysis is domain meaning, so it remains explicit. Store request projection is derived; there is no second stored filter. |

The three files with no remaining declaration are retained as explanatory placeholders so each original file has a visible disposition. They should be removed when implementing the design.

## Meaning of the proposed vocabulary

`Child` gives a selected domain child the parent's lifetime. `Presenting` gives it an optional presentation lifetime. Both use the original domain key path as their coordinate. They do not declare a second domain hierarchy. `Observing` follows a stream; `Requesting` represents an explicit submitted request. Neither is interchangeable with the other.

A composition automatically retains the domain's callable operations. A selected child owns calls routed into that child; otherwise the containing interface owns execution. Thus the root lists deletion and the scoped lists deletion are the same domain operation reached through different store routes, not two independent commands. Routing must retain the originating scope, task, cancellation, and failure ownership.

The dismissal modifier's `before` argument selects a domain operation and projects its argument, rather than describing the generated action tree. It must match both root and scoped sends exactly once, dismiss only a page with the matching list, and run before dispatch. A failed deletion therefore still closes the page, matching the checkpoint. Presentation and unrelated page calls retain their own lifetime. This modifier observes execution; it does not execute the deletion a second time.

`commands: Reminders.self` selects an ancestor capability, not a new `Reminders` instance or a process-wide dependency. The child receives the exact instance supplied to its enclosing composition. Standalone page and editor compositions still need an explicit `.interface(reminders)` host binding. If multiple candidate ancestors exist, the caller must disambiguate: no global lookup or name-based heuristic.

The `rows` lens selects the observed result's collection; `draft` selects a writable record projection. These choices replace bridge-specific structural marker protocols. Their types constrain the operation relationships. The selected deletion prism supplies an optional record identifier. These are typed relationships, not reimplemented records or calls.

`some Feature` on `editing` is intentionally opaque. Reusing it must compose through feature associated types and typed operation relationships, without requiring the caller to reveal a concrete `Editing<Reminder>` representation. If listing needs richer editing capabilities than `Feature` provides, the implementation must expose an appropriate editing protocol or composition constraint; it cannot downcast an opaque feature to recover them.

The page feature projects its request fields, allowing `filter.list` without exposing `contents.request`. That is a view of existing request storage. Conflicting request/state member names require a deliberate disambiguation API; a derivation must not silently shadow a member.

## Derivation responsibilities and algebra

- Interface owns operation signatures, child coordinates, canonical calls, and their optics. Existing domain values remain the payloads.
- Feature composition interprets selected children as a product of states and a sum of routed actions. Presentation adds an optional child state; lifecycle logic controls the corresponding effect lifetime.
- Observing interprets a stream-valued operation over time. Requesting interprets request execution and its result/error lifecycle. Task identifiers belong to these runtime interpretations, not to pure product or sum algebra.
- Listing combines observation, a result projection, and explicitly selected editing/deletion behavior. Editing combines the three typed operations with a writable draft lens and explicit policies. Neither invents business semantics from names.
- The dismissal rule is application policy over a selected operation and presentation. Algebra supplies typed composition and projection, not the rule that deletion should close this particular page.

## Constraints that block literal implementation

1. **Extension conformance generation.** The compact `@Feature extension X { … }` spelling is aspirational. A member macro cannot simply add `: FeatureProtocol` to that source extension, and an extension macro cannot be relied upon to attach to an extension and produce the needed conformance. Swift 6.4 also will not lower a conformance-producing extension macro nested inside another macro's extension output. A current-compiler implementation must retain an explicit source `extension X: FeatureProtocol` and use a suitable member/body derivation, or change the declaration owning `X`. Do not claim the shorthand works merely by nesting TCA's `@Feature` in emitted syntax.
2. **Nested types.** A macro on `Reminders` cannot extend `Reminders.Read`, its calls, or its payloads. Interpretations remain attached to the existing types individually. Any needed conformance must originate on its own attached type or be eliminated through a projection-based API. No top-level surrogate feature types.
3. **Semantic type information.** A syntax macro cannot inspect arbitrary imported operation signatures or type-check a result builder. Typed Interface metadata and protocol constraints must provide what generic implementations need. If deriving a heterogeneous composition requires syntax-owned members, the feature declaration must supply accessible syntax; importing another package's Core to re-derive its output is not an alternative.
4. **Typed errors.** `.notFound` can be inferred only when the selected update operation retains its declared error type. If that information is erased at the bridge boundary, the typed overload must be implemented first. Inferring a domain failure from an `any Error` value without that relationship is unsound.
5. **Protocol requirements versus structural similarity.** Swift does not infer nominal conformance from matching members. Removing `EditableRecord` and `ListingValue` requires changing the algorithms to accept the selected lenses, not silently assuming the existing generic constraints will compile.
6. **Canonical optics.** Dropping the consumer CasePathable extensions requires compatible optics at every actual consumer boundary. It is blocked wherever an immutable dependency insists on a missing nominal conformance. Reconstructing a parallel call/action hierarchy is not an acceptable fallback.

No new package is proposed. The Interface package continues to own domain derivations; the Interface–TCA bridge owns interpretations. All package dependencies remain URL-based. Any eventual implementation must keep platform minimums at 27, enforce MemberImportVisibility as an error, and validate the exact reminders workspace after completing the implementation.
