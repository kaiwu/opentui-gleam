# opentui-gleam Roadmap

## Mission

Build a **Gleam-first OpenTUI ecosystem** that lets developers use OpenTUI capabilities from Gleam directly, without depending on TypeScript runtime layers.

The goal is not only to expose raw native bindings. The goal is to grow a package and module ecosystem in Gleam that plays a role similar to the upstream OpenTUI TypeScript packages:

- a low-level core binding layer
- ergonomic Gleam runtime APIs
- higher-level Gleam UI and widget abstractions
- runnable examples and demo applications
- testing support
- optional advanced capability slices

## Current Status

The repository already has a good foundation, but it does **not** yet provide full OpenTUI coverage from Gleam alone.

### What is already in place

- raw FFI access in `packages/opentui_core/src/opentui/ffi.gleam`
- Bun FFI shim in `packages/opentui_core/src/opentui/ffi_shim.js`
- direct native loading from `native/opentui-zig/packages/core/src/zig/lib/<target>/`
- basic high-level wrappers:
  - `packages/opentui_runtime/src/opentui/renderer.gleam`
  - `packages/opentui_runtime/src/opentui/buffer.gleam`
  - `packages/opentui_runtime/src/opentui/edit_buffer.gleam`
  - `packages/opentui_runtime/src/opentui/text.gleam`
  - `packages/opentui_runtime/src/opentui/types.gleam`
  - `packages/opentui_core/src/opentui/runtime.gleam`
- demo registry and examples:
  - `packages/opentui_examples/src/opentui/catalog.gleam`
  - `packages/opentui_examples/src/opentui/examples/*`

### What is currently demonstrated

- renderer lifecycle and terminal setup
- buffer drawing
- basic text editing
- pure Gleam text wrapping/truncation helpers
- direct runnable demos through `gleam run -m ...`

### What is still missing

The current Gleam surface is still missing major OpenTUI capability areas:

- full `TextBuffer` wrapper
- full `EditorView` wrapper
- syntax style wrapper
- higher-level input and event model
- hit-grid wrapper APIs
- clipboard wrapper APIs
- callback/event wrapper APIs
- layout/renderable abstraction layer
- reusable widgets/components
- testing utilities
- optional advanced slices like 3D/WebGPU
- any equivalent of upstream framework adapter layers, if Gleam eventually needs them

## Upstream Package Reference

The upstream OpenTUI TypeScript ecosystem currently centers around:

- `@opentui/core`
- `@opentui/react`
- `@opentui/solid`
- `@opentui/web`

Important detail: upstream keeps most capability slices attached to `@opentui/core` as sub-surfaces, including:

- testing
- 3d
- runtime-plugin
- runtime-plugin-support

For Gleam, the package split should mirror the **capability boundaries**, not the framework names.

## Target Hex.pm Package Plan

### 1. `opentui_core`

Purpose:

- lowest-level native bridge
- raw FFI handles and declarations
- minimal stable substrate for everything above it

Expected contents:

- `opentui/ffi.gleam`
- `opentui/ffi_shim.js`

This package should stay small and mechanical.

### 2. `opentui_runtime`

Purpose:

- ergonomic Gleam wrapper layer over the raw FFI
- main entrypoint for developers who want to use OpenTUI from Gleam

Expected contents:

- `opentui/renderer.gleam`
- `opentui/buffer.gleam`
- `opentui/edit_buffer.gleam`
- `opentui/text.gleam`
- `opentui/types.gleam`
- runtime-side helper modules that are not demo-specific

This should become the primary publishable Gleam package first.

### 3. `opentui_ui`

Purpose:

- Gleam-native UI/renderable/component layer
- the package that makes OpenTUI feel natural and composable in Gleam

Expected future contents:

- layout abstractions
- renderable tree model
- text view / scroll view / code view helpers
- input widgets
- textarea/select-like widgets
- diff and line-number widgets
- composable panel/status widgets

This is the closest analog to the higher-level experience provided upstream through React/Solid.

### 4. `opentui_testing`

Purpose:

- testing support analogous to upstream testing helpers

Expected future contents:

- test renderer
- synthetic key/mouse input helpers
- frame snapshot helpers
- demo and widget test support

### 5. `opentui_3d` (optional)

Purpose:

- isolate heavyweight optional graphics/3D capabilities from the main runtime packages

This should remain optional and only be pursued after the main Gleam runtime/UI layers are mature.

### 6. `opentui_examples` (optional)

Purpose:

- keep runnable demos and showcase apps distributable without mixing them into the main runtime package surface

This package is useful once there are enough demos and example apps to justify separate publication.

## Recommended Migration Boundaries

### Keep in the low-level core layer

- raw FFI declarations
- opaque native handle types
- JS shim loading and symbol bridging

### Move into the runtime layer

- safe wrappers around native operations
- byte-size-aware string helpers at FFI boundaries
- renderer/buffer/text editing convenience functions
- eventually text buffer, editor view, syntax style, selection, clipboard, hit-grid wrappers

### Grow in the UI layer

- reusable render helpers
- composable view data structures
- widget implementations
- high-level interaction models
- non-trivial layout abstractions

### Keep examples separate from core/runtime

- catalog and demo registry
- runnable examples
- showcase applications

## Delivery Phases

### Phase 1 — Stabilize the binding foundation

Goals:

- keep the direct native-loading model stable
- maintain build/test/demo verification
- continue cleaning the raw FFI layer so it remains predictable and narrow

Deliverables:

- stable `opentui/ffi.gleam`
- stable `opentui/ffi_shim.js`
- explicit module boundaries between low-level and wrapper layers

### Phase 2 — Fill in runtime coverage

Goals:

- make the current missing imperative core capabilities accessible from ergonomic Gleam APIs

Priority additions:

- `text_buffer`
- `editor_view`
- `syntax_style`
- selection support
- hit-grid helpers
- clipboard support
- callback/event wrapper layer

Deliverables:

- broad runtime API coverage for the main non-framework OpenTUI features

### Phase 3 — Build Gleam-native UI abstractions

Goals:

- move beyond imperative demos and expose composable Gleam UI building blocks

Priority additions:

- layout primitives
- text and box abstractions
- scrolling and viewport helpers
- input and textarea widgets
- select/tab-like controls
- code/diff/line-number style widgets

Deliverables:

- a real `opentui_ui`-style package surface

### Phase 4 — Expand demos into a real showcase ecosystem

Goals:

- demonstrate the bindings and UI layers through multiple Gleam-native examples

Priority additions:

- more ports of simple upstream TS examples
- examples that exercise text buffers, editor views, widgets, and layout systems
- app-like demos rather than only feature snippets

Deliverables:

- broad example coverage
- reusable demo support modules

### Phase 5 — Add testing and optional advanced packages

Goals:

- make the ecosystem robust enough for long-term package growth

Priority additions:

- `opentui_testing`
- optional `opentui_3d`
- possibly `opentui_examples` as a separate published package

## Short-Term Priorities

The next most valuable steps are:

1. add `text_buffer` wrapper module
2. add `editor_view` wrapper module
3. add `syntax_style` wrapper module
4. create a proper input/event abstraction above demo loops
5. port more upstream examples using reusable Gleam modules
6. expand test coverage beyond catalog/text helpers into runtime-facing APIs where practical

## Non-Goals for Now

These should not block the main roadmap:

- direct imitation of React/Solid package names in Hex
- framework-specific adapter layers before the Gleam-native runtime/UI story is strong
- optional 3D/WebGPU work before the main runtime and UI layers are mature

## Success Criteria

We can claim a strong Gleam-first OpenTUI ecosystem when:

- major core OpenTUI capabilities are wrapped in ergonomic Gleam modules
- common TUI applications can be built in Gleam without falling back to TS runtime code
- demos exercise multiple capabilities through reusable abstractions, not one-off imperative code
- package boundaries are clear enough to publish stable Hex packages
- testing exists for both pure helpers and runtime-facing behaviors

## Near-Term Publishable Story

If packaging started soon, the realistic order would be:

1. `opentui_core`
2. `opentui_runtime`
3. later `opentui_ui`
4. later `opentui_testing`
5. optional `opentui_3d`
6. optional `opentui_examples`

That order matches the current codebase maturity and keeps the published story honest.
