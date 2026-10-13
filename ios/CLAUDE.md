# iOS Conventions

My general conventions for any iOS app. App-agnostic.

## Architecture
- **MVVM.** Views are dumb; ViewModels hold state + orchestration; logic lives below.
- **Single source of truth.** Shared state in one owner (a store), injected — never a singleton.
- **Dependency injection via a composition root** (`App.init`). Build dependencies once, inject down. No global access.
- **Thin ViewModels.** They gather inputs, call calculators/services, map to display models. No heavy logic inside.
- **Stateless calculators = structs; shared mutable state = classes.** Pure math goes in pure-function structs.

## Layers
- **DTO** (`Decodable`, mirrors the API) → **Domain** (app-owned models) → **Display/view-state** (formatted strings + flags, produced by the ViewModel).
- Views consume display models only — never raw DTOs, never formatting logic in the view.
- Network behind a protocol-based layer; one generic fetch, endpoints as an enum building URLs via `URLComponents`.

## Naming
- Protocols: `...Protocol` (e.g. `FooViewModelProtocol`).
- Display structs: `...State` (e.g. `RowState`, `SummaryState`).
- Clear, consistent verbs across a type — don't mix styles (`calcFoo` vs `fooCalc`).

## Code style
- Swift concurrency: `async/await` + `Task` cancellation. Not Combine for new code.
- `@Observable` + `@MainActor` for ViewModels/stores. `@Bindable`/`Binding(get:set:)` when a value is behind a protocol.
- Debounce with `.task(id:)`, not timers.
- Cross-platform: guard iOS-only APIs with `#if os(iOS)` helpers so macOS builds stay clean.
- Inject dependencies behind protocols so they're swappable/mockable.

## Testing
- Use Swift Testing (`@Test`, `#expect`, `#require`). `#require` for preconditions/unwraps.
- Test the **real component**, mock its **dependencies** — never test the mock itself.
- Assert **behavior**, not just return values (e.g. a cache hit calls the network **zero** times — use a spy).
- Make one **configurable** mock (returns/throws per test) rather than many mock classes.
- Pure calculators are the easiest, highest-value first tests.

## Avoid
- "Manager" catch-all types — split by responsibility (calculator, formatter, store).
- Closures injected into ViewModels for wiring — call the store/service directly.
- Heavy logic or rate/config dependencies on `@Model` / data models — keep them data.
- Macros/property wrappers for domain logic (wrong tool; they're for boilerplate/stored-property behavior).
- Formatting inside calculators — keep a separate formatter.
- Creating a new ViewModel on every view re-render — cache/own it so state survives.
- Singletons and global state.
