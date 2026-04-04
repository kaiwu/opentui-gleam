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
- `opentui_examples` → may depend on `opentui_core` and `opentui_runtime`

Do not introduce reverse imports.

## Module Namespace Guidance

Preserve the `opentui/...` module namespace across packages where possible.

The package boundary should change more often than the public module path.

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

### 3. Keep examples separate

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

Use the repo-level helper scripts when useful:

- `./scripts/build-all.sh`
- `./scripts/test-all.sh`

## Documentation Expectations

Keep `README.md`, this file, and `ROADMAP.md` aligned with the actual monorepo structure.

If package boundaries change, update the docs in the same change.
