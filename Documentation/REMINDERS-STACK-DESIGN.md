# Minimal Reminders stack: static design pass

This pass covers every source module, the app host, package declarations, and
existing test expectations affected by the source changes. It is aspirational,
not an implemented or compiling refactor. No build, package resolution, macro
expansion, or test execution was performed. Supporting packages are unchanged.

## Scope decisions

| Layer | Selected end-state | What remains explicit |
| --- | --- | --- |
| List | Derive constructor, draft, and draft projection from one declaration | ID, title, defaults, blank predicate, default-list title |
| Reminder | Derive constructor, draft, and draft projection from one declaration | ID, list, title, completed, creation time, defaults, blank predicate |
| List.Entry | Derive its assigning constructor | List, open-reminder count, identity projection |
| Reminders | Preserve operation signatures and composition; derive checked sending interfaces and a primary Request alias | Read/observe distinction, completion-only update, filters, errors, child selection |
| Read values | Derive constructors and retain default empty collections | Named rows/lists coordinates, rather than anonymous arrays |
| Dependency | Derive unimplemented test behavior from canonical operations | DependencyValues entry, explicit finished-stream fallback |
| SQL | Derive assigning constructors | Existing schema records, conversion maps, selected count, column rename and position |
| SQLite | Reuse a generic async-sequence-to-stream adapter and canonical Request aliases; remove Schema namespace | Transactions, migrations, identity/time generation, update-only semantics, ordering, joins, cascade, default-list installation |
| Sample | Derive constructor | Stable fixture identities, titles, completion state, timestamps |
| Feature | Compose canonical children and editing policy; discard on deletion | Observation/presentation distinction, blank policy, commit timing, deletion coordination |
| SwiftUI | Full/row/editor presentations, initializer references, reusable task failure presentation | Labels, layout, accessibility, callbacks, navigation, insertion and toolbar placement |
| Host | Open the real database and construct one store | Startup dependency setup and store lifetime |

## The two questioned policies

### Keep blank handling

`blank: .discardNewDeleteExisting(\.isBlank)` is an application rule, not algebra
and not a workaround. It supplies two current behaviors:

- Dismissing an untouched new reminder does not insert an empty record.
- Clearing an existing reminder's title deletes it on commit.

Without it, the current generic editing default saves both kinds of blank draft.
That is an observable behavior change. Keep this selection once at the root
editing policy; do not bake it into generic Editing or infer it from a title.
Blankness is now defined once on each domain draft, rather than repeated on the
record and its draft. Record callers use `.draft.isBlank`.

### Remove broad ignored-update failures

`ignoreUpdateFailure: Update.Error.notFound` previously hid every matching
update failure during commit, including failures unrelated to user deletion.
The aspirational lifecycle now distinguishes:

- Normal dismissal: apply the selected commit policy.
- Deleting the edited reminder: discard that session before the delete call.
- Deleting its list: discard the matching page and its owned editing sessions.

Discard must bypass commit even when the child dismounts. It cannot be implemented
as setting the existing commit-on-dismount state to nil without recording the
termination reason. That would preserve the race while merely removing its
error handling. There is one session state, with a lifecycle outcome, not a
parallel discarded-session model.

A genuine not-found update still fails and must reach the existing task-error
surface. This deliberately stops silently accepting external deletion races.
The previous behavior of closing the affected editor/page before a delete call
is preserved, including when deletion later fails; unrelated sessions remain.
In-flight commits require lifecycle coordination as well: do not claim that
discard retroactively cancels a write already executing. This remains required
implementation and integration work.

## New derivation contracts

### @Memberwise — swift-product / Product Macro

Generate the public assigning initializer from stored properties and their
source defaults. No independently maintained field list. Respect access levels,
let versus var, generic parameters, and initialization ordering. It is a member
macro and can coexist with Table/Selection inspecting the original stored fields.
Re-export it from the existing Interface Macro facade.

### @Draft — swift-product / Product Macro

The named exclusions choose the complement of a stored-property product:
`Reminder` excludes id and created; `List` excludes id. Diagnose unknown or
repeated field names. Derive the named Draft, field defaults, writable draft
projection preserving excluded fields, and reconstruction initializer taking
the excluded fields plus the draft. Preserve current initializer argument order,
including the unlabeled draft argument, rather than making callers map fields.

Draft must use the canonical product derivation, with @Memberwise attached where
its output is needed. It must not implement another package's product algorithm
through Core. Existing @Product derives protocol operation products; it cannot
simply be applied to these structs unchanged. Supporting stored-value products
and their projection is a real extension to the derivation design, not a claim
that today's @Product already provides these members.

Hashable/Sendable behavior must be checked from the field types. Generated nested
Draft declarations may carry native conformances directly where legal; an
extension macro placed inside emitted extension output is not a fallback.

### @Interface(.sendable) — swift-interface / Interface Macro

Require canonical stored operation closures and child interfaces to be Sendable
and generate checked conformance on the attached interface. Do not replace the
removed @unchecked Sendable declarations with hidden assertions. Preserve the
existing canonical operation derivations and request/call algebra. Each explicit
interface declaration selects this requirement, so no macro needs to extend a
different attached type. Diagnose incompatible captures or implementations.

`Request` aliases the already selected primary operation's Input. The overloaded
Read interface retains its primary zero-argument observation and its ID lookup;
no parallel request schema is generated. Storage extensions no longer mention
Run merely to reach the request type.

### @TestDependency — swift-interface / Interface Dependencies

A new optional integration target/product in the existing swift-interface
package, not a new package and not a Dependencies import in the domain target.
It derives testValue using canonical product/operation metadata, reports each
unimplemented operation, and recursively constructs child interfaces. It attaches
to the explicit TestDependencyKey extension and generates members of that type.
The DependencyValues extension remains handwritten: a macro attached to Reminders
cannot also extend DependencyValues.

The explicit `streams: .finished` fallback preserves the former test behavior
for nonthrowing stream-producing operations. Do not invent placeholders for
arbitrary nonthrowing outputs: require a supplied fallback or diagnose them.

### eraseToThrowingStream — swift-standard-library-extensions

Generic AsyncSequence adaptation replaces the local continuation/Task loop.
Preserve initial values, ordering, completion, errors, cancellation, and release
of observation resources. Do not start an uncancelled detached producer. This
adapter is proposed supporting work, not an existing API claim.

## What was actively removed

- Repeated handwritten record/draft fields, copy assignments, and constructors.
- Duplicate record-level isBlank predicates.
- The handwritten unimplemented dependency tree and unchecked sendability list.
- The local database stream-adaptation loop.
- Empty Reminders.Schema namespace: database and migration entry points are on
  Reminders in the SQLite module.
- Automatic app debug fixture seeding. Test fixture seeding remains explicit.
- Automatic debug database erasure on schema changes. Real migrations remain.
- Blanket suppression of update-not-found errors during editing commit.

## Why remaining persistence code is not simply deleted

SQL records currently repeat domain fields while adding position and renaming
list to listID. This is remaining duplication against the no-parallel-structures
objective, not a newly approved exception. It is explicitly unresolved here.

A hypothetical macro on Reminder that emits an extension containing @Table
Record cannot rely on extension-macro lowering inside that emitted extension.
A macro attached to a storage wrapper also cannot extend the external Reminder
type. Moving @Table onto the domain would couple the value module to persistence
and is not the selected design. No fictitious `@Storage(of:)` call site is used
to hide this constraint. Eliminating the adapters requires a legal composition
of the table derivation and canonical product projection, verified against the
actual table macro, before changing those declarations.

Keep migrations, FK cascade and foreign-key configuration, append ordering,
missing-record errors, controlled UUID/date dependencies, and the transaction
that restores the default list. These express behavior or integrity, rather
than mechanical wrappers. Keep completion as a narrow write: replacing it with
a whole-record update can overwrite fields changed since observation.

Keep the primary value wrappers, direct single-record read, and explicit errors.
They provide meaningful named coordinates and tested API behavior. Removing
these just because the current screen uses a subset would change the domain
rather than derive its mechanics.

## Integration status

Consumer Package.swift declares the proposed Interface Dependencies product and
explicit macro/stream-adapter dependencies. All owning packages are already in
reminders-architecture.xcworkspace; no path dependencies or new package references
were introduced. The proposed product and macros do not exist yet, so package
resolution/building is intentionally deferred with implementation.

Existing tests were adjusted statically for renamed view inputs, database entry
points, draft blankness, and the decision that observed rows remain unchanged
while an inline editor presents a draft. No coverage was deleted and no test was
run. Discard-vs-commit, stream cancellation, derived defaults, sendability, and
macro composition all require implementation and validation before this source
can be called working. See REMINDER-PRESENTATION-DESIGN.md for the view contracts.
