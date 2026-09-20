# Aspirational reminder call sites

> Historical design checkpoint: `bb74c26`. Statements below about unimplemented
> APIs describe that checkpoint. See [implementation status](REMINDERS-IMPLEMENTATION.md)
> for the implemented contracts, deviations, and validation.

This is a static source design, not an implemented or validated API. No builds
or tests have run for this pass. Supporting packages remain unchanged.

## The chosen boundaries

- `Reminder.View` presents the canonical draft in a full form.
- `Reminder.View.Row` presents an existing reminder with ordinary callbacks.
- `Reminder.View.Row.Editor` presents the same draft compactly with a binding
  and submission callback. It has no dependency on a feature store.
- `Reminder.View.Completion` owns the shared visual completion control.
- `Reminders.editing` selects the actual create/update/delete operations, draft
  lens, blank policy once.
- The page selects an editing policy and its lifecycle. It does not declare a
  separately named session feature or repurpose the Update operation as one.
- Inline placement is a view policy; persistence and deletion coordination are
  feature policies. Full and compact views own neither.

## Feature syntax

```swift
Listing(self, rows: \.rows, editing: \Reminders.editing)
    .editing.commit(on: .dismiss)
    .editing.discard(on: .delete)
```

This preserves the user's compact composition and lifecycle modifiers. The
policy reference is a typed key path: `Reminders.editing` is an instance member,
not a static policy or permission to construct another Reminders instance.
The enclosing interface supplies its actual implementation, including overrides.

`Listing` is a composition of independent observation, command execution, and
optional editing capabilities. Its shorter spelling must not perpetuate a
monolithic implementation. Observation exposes original query rows, without a
second overlay of drafts. Inline presentation alone chooses row substitution.

The owner type follows from the policy key path. Record and draft types follow
from the policy's selected lens. Creation, update, deletion, and record identity
follow from its explicitly selected operations and existing Interface/algebra
metadata. The page does not restate those coordinates.

`.delete` means the deletion operation selected by that policy, not an operation
chosen by spelling or by an arbitrary ID-to-Void signature. Discard matches
that request's identity to the current session before command execution. It
must leave unrelated editors alone and must bypass commit. Matching list deletion
discards the page and its owned sessions. There is no blanket not-found error
suppression. The deletion/cleanup ordering must be validated later.

`.dismiss` means removal of the logical editing session, including submission,
Done, or owner removal. It must not mean an incidental SwiftUI disappearance.
Blank-draft and failure behavior remain explicit in the root policy.

The root uses `Children(\.read, \.lists)`: product composition from canonical
Interface child coordinates. Selection remains explicit because an interface
property does not by itself imply a mounted child rather than presentation.

## View syntax

```swift
InlineEditing(
    store.rows,
    editing: $store.editing,
    insertion: .afterLast,
    row: { reminder in
        Reminder.View.Row(
            reminder: reminder,
            complete: { store.update.complete(reminder.id, !reminder.completed) },
            delete: { store.delete(reminder.id) },
            edit: { store.editing = .init(reminder) }
        )
    },
    editor: Reminder.View.Row.Editor.init
)
```

`InlineEditing` has one presentation responsibility: replace the selected row
with its editor, or place a new editor at the explicitly selected position.
Its editor closure receives `(Binding<Draft>, () -> Void)`, matching the existing
editor initializer's binding and submit inputs. Submission dismisses the session;
the feature's explicit lifecycle policy determines whether that commits.
There is no store-specific initializer added to the record view and no second
session representation. The view adapter projects the existing session.

`@View` must derive binding-preserving initializers. Type/argument order supplies
the initializer-reference match; it must not inspect property names to invent
persistence behavior. Ordinary callbacks remain ordinary closures, without bind
wrappers or deferred-sender abstractions.

`TaskFailure` is a reusable task-state presentation, not another error model.
It renders the first non-nil task error in argument order, using its localized
description and red styling. The optional title creates a section only when an
error exists. The call site retains font choice. Thus the existing root error
priority and create-form empty/error behavior remain visible and preserved.

The empty request spelling `store.lists.create = .init()` forwards the canonical
request's default construction, including its default-constructible draft. It
is available only when every required input can be supplied by declared defaults;
it does not invent field values. Page creation still explicitly supplies a list.

## Full presentation remains available

The page still uses inline editing. A containing screen could instead use:

```swift
.sheet(item: $store.editing) { editing in
    NavigationStack {
        Reminder.View(draft: editing.$draft)
            .navigationTitle("Reminder")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done", action: editing.dismiss)
                }
            }
    }
}
```

This is an alternative, not a second installed editor. There is no Cancel button
under commit-on-dismiss semantics. Discard requires its own explicit outcome.

## Deliberately explicit

The algebra does not choose screen layout, field labels, row spacing, symbols,
accessibility text, toolbar placement, completion toggling, deletion affordances,
navigation titles, blank handling, commit timing, or insertion position. Hiding
those choices in an application-specific macro would shorten source by hiding
the application, rather than deriving it.

Store-backed views retain explicit capability annotations. In particular,
Reminders.Read.View consumes the root Reminders capability. A syntactic macro
cannot assume that lexical nesting determines a view's required store.

The existing command closures document real interaction semantics. Inverting a
Bool and sending it immediately differs from changing a session draft. They
must not be unified through a binding that conceals persistence or failure.

## Required implementation and constraints

The proposed Listing policy-key-path overload and editing modifiers, Children,
InlineEditing callback contract, TaskFailure, binding initializer derivation,
and default request forwarding require supporting work. This pass adds only
call sites; it does not claim these APIs already exist.

Reuse the canonical Interface operations, product/coproduct projections, draft
lens, and identity. Consume their generated metadata rather than re-parsing
another package's Core or building parallel state, action, or session schemas.
If that metadata is missing, its owning derivation must expose it explicitly.
Ambiguous operation/lens relationships require selection, not heuristics.

Swift extension macros can only extend their attached type, and cannot rely on
lowering extension macros nested inside generated extension output. No part of
this design requires a macro on Page to extend Reminder or a separately generated
session type. If an implementation requires such a conformance, that shortcut
is blocked: it needs an explicit, legal attachment on the actual type.

Preserve URL dependencies, the exact integration workspace, explicit imports
under MemberImportVisibility, and platform minimum 27. Imports have not been
pruned speculatively while macro expansions remain unimplemented.
