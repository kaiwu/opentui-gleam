# Agent Guidelines for opentui-gleam

## Project Mission

This repository is building a **Gleam-first OpenTUI ecosystem**.

The long-term goal is not just thin bindings. The target is to provide OpenTUI capabilities as **Gleam packages and modules** in the same spirit that the upstream TypeScript monorepo provides multiple packages, examples, and growth paths for its own ecosystem.

That means work here should generally move toward:

- richer Gleam bindings over the OpenTUI native surface
- reusable Gleam runtime helpers where necessary
- Gleam-native demos and example applications
- functional, composable APIs rather than monolithic imperative demo code
- clear separation between low-level bindings and higher-level Gleam ergonomics

## Current Structure

### Canonical layout

- `src/opentui/ffi.gleam`
  - Low-level `@external` boundary to `src/opentui/ffi_shim.js`
  - Keep this focused on raw native access and opaque handle types

- `src/opentui/runtime.gleam`
  - Runtime helpers above raw FFI
  - Contains JS-loop helpers and logging helpers that are not part of the core binding surface

- `src/opentui/*.gleam`
  - Reusable Gleam binding modules and ergonomic APIs
  - Current examples: `buffer`, `renderer`, `edit_buffer`, `text`, `types`, `catalog`

- `src/opentui/examples/*.gleam`
  - Runnable demo modules
  - Each demo should be directly runnable with `gleam run -m <module>`

- `src/opentui/examples/common.gleam`
  - Shared demo bootstrap/chrome helpers
  - Prefer growing reusable demo support here over copy-pasting layout scaffolding

- `src/opentui.gleam`
  - Default package entrypoint
  - Should act as a catalog/launcher/help surface, not a hardwired single demo forever

- `src/opentui/ffi_shim.js`
  - Single Bun FFI shim with one `dlopen()` call and all exported JS bridge functions
  - Avoid pulling TypeScript runtime logic from the upstream submodule into this layer

- `native/opentui-zig/`
  - Upstream OpenTUI submodule
  - Treat this as the native source of truth and inspiration for ecosystem structure, including the built shared library output under `packages/core/src/zig/lib/<target>/`

## Architectural Direction

### 1. Prefer namespaced Gleam modules

New work should prefer `opentui/...` modules over adding more flat top-level modules in `src/`.

### 2. Keep bindings and demos separate

- Binding modules belong under `src/opentui/`
- Demo/app modules belong under `src/opentui/examples/` or future app-oriented namespaces

Do not mix demo-specific orchestration into the low-level binding layer unless it truly belongs there.

### 3. Favor FP composability

When implementing demos and higher-level APIs, prefer:

- pure data transformations
- small render helpers
- explicit state records
- composition through functions and modules

Avoid growing giant single-file demos that combine setup, state mutation, layout, rendering, and platform control in one place if the code can reasonably be decomposed.

### 4. Grow toward package-like boundaries

Even though this repo is currently one Gleam package, structure code as if it may eventually split into clearer package domains, such as:

- core bindings
- runtime helpers
- widgets/components
- demo/example apps

Design module boundaries so this split is possible later without large rewrites.

## Demo Conventions

- Every demo should have a stable runnable module path, e.g. `opentui/examples/editor`
- The default `gleam run` path should not be the only way to access demos
- Add new demos to the catalog/registry so discovery stays centralized
- Prefer reusable helper functions over demo-local duplication

## Testing Expectations

When changing structure or runtime behavior:

- add or update `gleam test` coverage for catalogs/registries/module contracts
- run `gleam build`
- run `gleam test`
- run relevant demo entrypoints when practical (`gleam run -m ...`)

If JS shim behavior changes in a meaningful way and is practical to test directly, add runtime-side coverage as well.

## Documentation Expectations

Keep `README.md` and this file aligned with reality.

If you change module layout, demo entrypoints, or the intended ecosystem direction, update the docs in the same change.
