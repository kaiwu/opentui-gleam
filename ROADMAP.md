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

The repository has moved beyond a thin-binding foundation and now has a real monorepo shape with substantial runnable coverage. It still does **not** yet provide full OpenTUI coverage from Gleam alone, but it already demonstrates that the core/runtime/ui/examples split is viable and that many upstream demo ideas can be expressed in Gleam-first abstractions.

### What is already in place

- raw FFI access in `packages/opentui_core/src/opentui/ffi.gleam`
- Bun FFI shim in `packages/opentui_core/src/opentui/ffi_shim.js`
- direct native loading from `native/opentui-zig/packages/core/src/zig/lib/<target>/`
- high-level runtime wrappers:
  - `packages/opentui_runtime/src/opentui/renderer.gleam`
  - `packages/opentui_runtime/src/opentui/buffer.gleam`
  - `packages/opentui_runtime/src/opentui/edit_buffer.gleam`
  - `packages/opentui_runtime/src/opentui/text.gleam`
  - `packages/opentui_runtime/src/opentui/types.gleam`
  - `packages/opentui_runtime/src/opentui/text_buffer.gleam`
  - `packages/opentui_runtime/src/opentui/editor_view.gleam`
  - `packages/opentui_runtime/src/opentui/syntax_style.gleam`
  - `packages/opentui_runtime/src/opentui/input.gleam`
  - `packages/opentui_runtime/src/opentui/framebuffer.gleam`
  - `packages/opentui_runtime/src/opentui/animation.gleam`
  - `packages/opentui_runtime/src/opentui/grapheme.gleam`
  - `packages/opentui_runtime/src/opentui/physics2d.gleam`
  - `packages/opentui_runtime/src/opentui/math3d.gleam`
  - `packages/opentui_runtime/src/opentui/lighting.gleam`
  - `packages/opentui_core/src/opentui/runtime.gleam`
- a growing pure UI layer in `packages/opentui_ui`, including:
  - `opentui/ui.gleam`
  - `opentui/draw_plan.gleam`
  - `opentui/interaction.gleam`
  - `opentui/timeline.gleam`
  - `opentui/wireframe.gleam`
  - `opentui/simulation.gleam`
  - `opentui/frame_playback.gleam`
- demo registry and examples:
  - `packages/opentui_examples/src/opentui/catalog.gleam`
  - `packages/opentui_examples/src/opentui/examples/*`
- package-local test suites across `core`, `runtime`, `ui`, and `examples`

### What is currently demonstrated

- renderer lifecycle and terminal setup
- buffer drawing
- text wrapping/truncation helpers
- text-buffer and editor-view driven demos
- input, focus, scrolling, layout, and widget demos
- framebuffer, unicode, animation, and texture demos
- 3D and physics showcase demos
- direct runnable demos through `gleam run -m ...` and `./scripts/run-example.sh ...`
- pure intermediate representations for draw plans, interaction reducers, timeline helpers, wireframe planning, simulation state, and frame playback

### What is still missing

The current Gleam surface is still missing or only partially covers some major OpenTUI capability areas:

- deeper `TextBuffer` coverage and polish
- deeper `EditorView` coverage and polish
- broader syntax/highlighting wrapper coverage
- higher-level input and event model above demo loops
- hit-grid wrapper APIs
- clipboard wrapper APIs
- callback/event wrapper APIs
- a richer layout/renderable/widget surface in `opentui_ui`
- reusable testing utilities as a dedicated package or package surface
- optional advanced slices like a separately publishable 3D package
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

Status:

- initial package created
- first-pass `Element` tree and renderer added
- pure helper layers now include draw plans, interaction reducers, timeline helpers, wireframe planning, simulation reducers, and frame playback helpers
- many examples across phases 1–5 now depend on reusable lower-level `runtime` and `ui` modules instead of only demo-local imperative code

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

- continue deepening `text_buffer`
- continue deepening `editor_view`
- continue deepening `syntax_style`
- selection support polish
- hit-grid helpers
- clipboard support
- callback/event wrapper layer

Deliverables:

- broad runtime API coverage for the main non-framework OpenTUI features

### Phase 3 — Build Gleam-native UI abstractions

Goals:

- move beyond imperative demos and expose composable Gleam UI building blocks
- continue migrating proven demo-local pure helpers downward into `opentui_ui`

Priority additions:

- layout primitives
- text and box abstractions
- scrolling and viewport helpers
- input and textarea widgets
- select/tab-like controls
- code/diff/line-number style widgets

Deliverables:

- a broader `opentui_ui` package surface with reusable layout, interaction, planning, and widget building blocks

### Phase 4 — Expand demos into a real showcase ecosystem

Goals:

- demonstrate the bindings and UI layers through multiple Gleam-native examples

Priority additions:

- keep parity and behavior quality high across the now-broad demo catalog
- continue improving remaining gaps where the Gleam demos still get the point but are not yet ideal
- add more app-like demos rather than only feature snippets where useful

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

1. deepen `text_buffer` wrapper coverage where the current demos still need lower-level escape hatches
2. deepen `editor_view` and syntax-style coverage so editor/code demos depend less on demo-local assembly
3. create a proper higher-level input/event abstraction above raw demo loops
4. add hit-grid / clipboard / callback wrappers where upstream capabilities still have no ergonomic Gleam surface
5. continue extracting reusable widgets and layout helpers into `opentui_ui`
6. design a dedicated `opentui_testing` story for synthetic input, snapshots, and demo/widget verification

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
- the remaining runtime and widget gaps are small enough that the examples package is showcasing polish rather than compensating for missing lower-level surfaces

## Near-Term Publishable Story

If packaging started soon, the realistic order would be:

1. `opentui_core`
2. `opentui_runtime`
3. later `opentui_ui`
4. later `opentui_testing`
5. optional `opentui_3d`
6. optional `opentui_examples`

That order matches the current codebase maturity and keeps the published story honest.

## Execution Plan

Concrete work items derived from auditing the codebase against the roadmap above (2026-04-08). Each phase lists remaining work only — completed items are checked off.

### Phase 1 — Stabilize the binding foundation

- [x] `ffi.gleam` stable (72 @external declarations, 6 clean opaque handle types)
- [x] `ffi_shim.js` stable (native loading with multi-strategy resolution)
- [x] No upward imports from core to runtime, dependency flow is clean
- [x] Build scripts: `build-all.sh`, `build-native.sh`, npm prebuilt route all working
- [ ] Move `opentui_core/src/opentui/runtime.gleam` to `opentui_runtime` — it contains runtime orchestration APIs (event loops, demo loops) that belong in the wrapper layer, not the raw FFI layer
- [ ] Add JSDoc comment in `ffi_shim.js` documenting that the `_encodedChars` Unicode cache is single-threaded/sync-only

### Phase 2 — Fill in runtime coverage

- [x] `text_buffer.gleam` — all 6 FFI functions wrapped with safe API
- [x] `input.gleam` — comprehensive keyboard, mouse, hit-grid, event loop support (95 lines)
- [x] Hit-grid helpers — `clear_hit_grid()`, `add_hit_region()`, `hit_at()` wrapped in `input.gleam`
- [ ] `editor_view.gleam` — deepen beyond the current 3 functions; add viewport management helpers, cursor positioning, selection handling, scroll state
- [ ] `syntax_style.gleam` — add style composition helpers and higher-level styling patterns beyond raw `register()`
- [ ] Create `clipboard.gleam` — wrap `copy_to_clipboard_osc52` from FFI with byte-size handling
- [ ] Create `callbacks.gleam` — wrap `set_log_callback` and `set_event_callback` with ergonomic Gleam API
- [ ] Higher-level input/event model — an abstraction above raw demo loops so apps can compose event handling without reimplementing the loop pattern

### Phase 3 — Build Gleam-native UI abstractions

- [x] `ui.gleam` — 818 lines, core rendering pipeline with Box, Column, Text, Paragraph, Spacer
- [x] `wireframe.gleam` — 218 lines, complete 3D mesh rasterizer
- [x] `draw_plan.gleam`, `interaction.gleam`, `timeline.gleam`, `simulation.gleam`, `frame_playback.gleam` — partial but functional helpers
- [ ] Add `Row` element to `ui.gleam` — horizontal layout is completely missing, only vertical (Column) exists
- [ ] Add scrolling/viewport container — demos currently manage scroll offset manually via state cells; extract into a reusable `ScrollView` element or helper
- [ ] Add `TextInput` widget — currently hand-rolled per demo using `edit_buffer` from runtime
- [ ] Add `Select` widget — demos build selects manually with Column + Text + external selection state
- [ ] Add `TabBar` widget — no tab switching control exists
- [ ] Add `CodeView` / line-number widget — code/diff rendering currently uses `editor_view` from runtime with no UI-layer abstraction
- [ ] Deepen `interaction.gleam` — currently only drag region/session; needs keyboard focus, event routing, interaction state machines
- [ ] Deepen `draw_plan.gleam` — only 3 operation types (FillRect, Text, Cell); underused vs. `ui.render_all()`

### Phase 4 — Expand demos into a real showcase ecosystem

- [x] 57 registered demos, all marked done across 5 phases
- [x] Shared infrastructure in `common.gleam` (462 lines, 8+ harness functions)
- [x] Phase-specific model modules extracted (phase2/3/4/5_model.gleam)
- [x] 71 total .gleam files in examples directory
- [ ] Migrate demos that still hand-roll layout/widgets onto Phase 3 UI abstractions as they land (Row, ScrollView, TextInput, Select)
- [ ] Add app-like demos that compose multiple widgets (e.g. a file browser, a settings panel) to prove the UI layer works for real applications

### Phase 5 — Add testing and optional advanced packages

- [x] 352 test functions across 30 test files (10 core, 95 runtime, 40 ui, 206 examples)
- [x] 3D capabilities implemented in `math3d.gleam`, `lighting.gleam`, `wireframe.gleam` — functional but not extracted
- [ ] Create `opentui_testing` package with:
  - [ ] Test renderer (headless renderer that captures draw calls without a terminal)
  - [ ] Synthetic key/mouse input helpers (generate input events programmatically)
  - [ ] Frame snapshot helpers (capture and compare rendered output)
  - [ ] Demo/widget verification harness
- [ ] Extract `opentui_3d` package — move `math3d.gleam`, `lighting.gleam` from runtime and `wireframe.gleam` from ui into a standalone optional package
- [ ] Prepare packages for Hex.pm publishing — verify each package has clean `gleam.toml` metadata, README, license, and stable public API surface
