# Agent Guidelines for opentui-gleam

## Project Mission

This repository is building a **Gleam-first OpenTUI ecosystem**.

The long-term goal is not just thin bindings. The target is to provide OpenTUI capabilities as **independent Gleam packages** in the same spirit that the upstream TypeScript monorepo provides multiple packages and ecosystem growth paths.

## Current Monorepo Structure

### Canonical layout

- `packages/opentui_core/`
  - Low-level FFI package
  - Owns `src/opentui/ffi.gleam`, `src/opentui/runtime.gleam`, and `src/opentui/ffi_shim.js`
  - Owns native loading logic and fallback npm package declarations

- `packages/opentui_runtime/`
  - Ergonomic Gleam runtime wrappers above the raw FFI layer
  - Current modules include `buffer`, `renderer`, `edit_buffer`, `text`, and `types`

- `packages/opentui_ui/`
  - Declarative UI package
  - Owns pure UI trees and single-pass rendering helpers
  - Current module includes `ui`

- `packages/opentui_examples/`
  - Runnable demos and catalog/help entrypoint
  - Contains `src/opentui/catalog.gleam` and `src/opentui/examples/*`

- `native/opentui-zig/`
  - Upstream native source of truth
  - Also the local build source for shared libraries during monorepo development

## Package Dependency Direction

Keep dependencies strictly downward:

- `opentui_core` → no internal package deps
- `opentui_runtime` → may depend on `opentui_core`
- `opentui_ui` → may depend on `opentui_core` and `opentui_runtime`
- `opentui_examples` → may depend on `opentui_core`, `opentui_runtime`, and `opentui_ui`

Do not introduce reverse imports.

## Module Namespace Guidance

Preserve the `opentui/...` module namespace across packages where possible.

The package boundary should change more often than the public module path.

## FP Composability Principle

The preferred direction for this repository is **functional composability first**.

That means new UI work should prefer:

- algebraic data types over imperative drawing sequences
- pure `view(state) -> Element` style APIs where practical
- style and layout as data
- pure transformations over UI trees
- one final render pass that lowers pure UI data into runtime buffer calls

Prefer adding reusable declarative building blocks in `opentui_ui` instead of solving each new demo with bespoke coordinate-heavy rendering code.

Imperative buffer drawing is still valid at the FFI/runtime edge, but it should increasingly become the implementation detail beneath pure UI descriptions rather than the primary authoring model.

### FP migration guardrails

When improving the repository toward more functional composability:

- preserve all existing passing tests as a safety net
- add tests for each new pure abstraction before migrating demos or widgets onto it
- migrate one behavior or demo at a time instead of batching a large rewrite
- run the full repo test suite after each meaningful migration step
- prefer replacing imperative example logic with pure intermediate representations only when the new pure layer is itself reusable and testable

Do not treat FP refactoring as permission to temporarily weaken test coverage. The goal is to make the codebase more composable **without** losing the behavioral guarantees already captured by the current test suite.

## Architectural Direction

### 1. Keep `opentui_core` mechanical

`opentui_core` should remain focused on:

- opaque handles
- raw `@external` declarations
- JS shim integration
- native library resolution

Avoid demo logic or high-level UI logic here.

### 2. Grow `opentui_runtime` into the main user-facing API

This package should provide safe, ergonomic wrappers over core primitives.

Future additions belong here before they belong in examples:

- `text_buffer`
- `editor_view`
- `syntax_style`
- selection and clipboard wrappers
- event abstractions

### 3. Grow `opentui_ui` around pure composability

This package should own:

- declarative element trees
- style/layout ADTs
- pure UI transforms
- pure layout planning APIs
- single-pass rendering from data into runtime buffer calls

Prefer exposing intermediate pure representations when useful, such as layout plans or serializable trees, so behavior can be tested without relying on terminal execution.

Prefer moving new composable view logic here instead of growing imperative example helpers.

### 4. Keep examples separate

`opentui_examples` should remain a consumer of the lower packages, not an owner of shared runtime logic unless that logic is clearly demo-only.

When reusable helper logic emerges from demos, move it downward into the right package.

## Self-Contained Package Rule

Each package should be independently publishable in principle. That means each package directory should contain its own:

- `gleam.toml`
- `src/`
- `test/`
- README and package metadata as needed

Do not rely on a single root `gleam.toml` for package identity.

## Testing Expectations

When changing package structure or runtime behavior:

- run `gleam build` in each affected package
- run `gleam test` in each affected package
- run relevant demos from `packages/opentui_examples`

When changing `opentui_ui` or other pure data-driven layers, add tests for the pure semantics, not just smoke tests for final rendering.

Examples of preferred pure tests:

- layout planning from style data
- stacking / spacing behavior
- wrapping and truncation behavior
- tree folds and serialization
- state-to-view transformations

The more layout and UI become data, the more behavior should be frozen with deterministic pure tests rather than only manual terminal checks.

Use the repo-level helper scripts when useful:

- `./scripts/build-all.sh`
- `./scripts/test-all.sh`

For larger composability refactors, prefer `./scripts/test-all.sh` as the default regression gate even if only one package was touched, unless there is a clear reason not to.

## Documentation Expectations

Keep `README.md`, this file, and `ROADMAP.md` aligned with the actual monorepo structure.

If package boundaries change, update the docs in the same change.
