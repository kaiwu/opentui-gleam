# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

A Gleam monorepo wrapping a native Zig TUI library (OpenTUI) into idiomatic Gleam packages. Target: JavaScript via Bun. All packages compile with `gleam build` targeting JS, using Bun FFI (`dlopen`) to call into the native shared library.

## Commands

```bash
# Build & test everything
./scripts/build-all.sh
./scripts/test-all.sh

# Build/test a single package
cd packages/opentui_core && gleam test
cd packages/opentui_runtime && gleam test
cd packages/opentui_ui && gleam test
cd packages/opentui_examples && gleam test

# Run a demo (from project root)
./scripts/run-example.sh editor
./scripts/run-example.sh shader-cube-demo

# Run a demo directly
cd packages/opentui_examples && gleam run -m opentui/examples/editor

# Show demo catalog
./scripts/run-example.sh catalog
```

The run-example script converts kebab-case IDs to snake_case module paths automatically. Any `.gleam` file under `packages/opentui_examples/src/opentui/examples/` is a valid demo target.

## Package Architecture

Six packages with **strict downward-only dependencies**:

```
opentui_core       → no internal deps (FFI layer)
opentui_runtime    → opentui_core (ergonomic wrappers)
opentui_ui         → opentui_core, opentui_runtime (declarative UI)
opentui_3d         → no internal deps (optional 3D math/lighting/wireframe)
opentui_testing    → opentui_core, opentui_runtime, opentui_ui (test utilities)
opentui_examples   → all above except opentui_testing (demos)
```

Never introduce upward imports. Each package is independently publishable to Hex.pm.

### opentui_core

Raw FFI bindings. Key files:
- `src/opentui/ffi.gleam` — 90+ `@external` declarations with opaque handle types (`Renderer(Int)`, `Buffer(Int)`, etc.)
- `src/opentui/ffi_shim.js` — Bun FFI shim: `dlopen()`, memory marshalling, input parsing, main loop variants (`runDemoLoop`, `runEditorLoop`, `runEventLoop`, `runAnimatedLoop`)
- `src/opentui/runtime.gleam` — high-level loop `@external` bindings

### opentui_runtime

Safe Gleam wrappers. Modules: `renderer`, `buffer`, `text`, `edit_buffer`, `text_buffer`, `editor_view`, `framebuffer`, `input`, `grapheme`, `syntax_style`, `animation`, `math`, `physics2d`, `types`, `clipboard`, `callbacks`, `app`, `runtime`.

Pure math modules (`physics2d`, `animation`) have **zero native FFI** except trig functions via `math_ffi.js` (wraps `Math.sin/cos/sqrt/atan2/pow/PI`).

### opentui_ui

Declarative UI as ADTs: `Element` (Box, Column, Row, Text, Paragraph, Spacer), `Style`, `Color`. Key functions: `render_all()` (single-pass render to buffer), `plan()` (pure layout), `fold()` (tree traversal). Includes `widgets.gleam` (ScrollState, InputState, SelectState, TabState, CodeView), `interaction.gleam` (DragSession, FocusGroup, ClickRegion), `draw_plan.gleam`, `timeline.gleam`, `simulation.gleam`, `frame_playback.gleam`.

### opentui_3d

Optional 3D package: `math3d.gleam` (Vec3, rotations, projection), `lighting.gleam` (Phong shading, multi-light illumination), `wireframe.gleam` (mesh rasterization, Bresenham lines). Self-contained with its own `math_ffi.js`.

### opentui_testing

Testing utilities: `testing.gleam` with synthetic input helpers (key/mouse event generators), state machine testing (`apply_events`, `apply_keys`), element tree inspection, layout plan inspection, frame snapshots, and widget verification harness (`trace_widget`).

### opentui_examples

59 demos across 5 phases. Shared infrastructure:
- `common.gleam` — color palette, terminal dimensions (80×24), demo runners (`run_static_demo`, `run_interactive_demo`, `run_animated_demo`)
- `catalog.gleam` — demo registry with `Demo(id, module, description)`
- `phase{N}_model.gleam` — pure data/functions for each phase's demos
- `phase{N}_state.gleam` — mutable state cells (`IntCell`, `BoolCell`, `StringCell`, `FloatCell`, `WorldHolder`) via JS FFI

## Key Patterns

**Opaque handle types**: Core types wrap raw integer pointers. `ffi.gleam` exposes constructors; runtime modules provide safe APIs.

**Color tuples**: `#(Float, Float, Float, Float)` — RGBA normalized 0.0–1.0 throughout the stack.

**Mutable state cells**: Gleam is pure, so mutable state uses JS-backed cells (`create_int` → `get_int`/`set_int`). Each phase adds its own state module with a co-located `.js` file.

**Demo runner pattern**: Demos call a shared runner from `common.gleam` which handles terminal setup/teardown, key input, and the render loop. Animated demos use `run_animated_demo(title, term_title, on_key, on_tick, draw)` driven by `setInterval(33)` (~30fps).

**FP composability**: Prefer algebraic data types over imperative drawing. UI as `fn(state) -> Element`. Animation as `fn(state, dt) -> state`. Pure rendering math (3D projection, Phong lighting, fractals, physics) implemented in Gleam, not delegated to JS.

## Gleam-Specific Gotchas

- **No semicolons in case expressions.** Write multi-line `case x { True -> a  False -> b }` not `{ True -> a; False -> b }`.
- **Type vs value imports.** When using a type in annotations, import with `type`: `import opentui/math3d.{type Vec3, Vec3}`. The value constructor `Vec3` alone doesn't import the type.
- **No sin/cos in stdlib.** Trig goes through `math_ffi.js` in opentui_runtime.
- **String byte size for FFI.** Many FFI calls require `gleam/string.byte_size(text)` alongside the text itself.
- **Unused imports are errors** (treated as warnings but should be cleaned up).

## Testing

Tests use `gleeunit`. Test files live in each package's `test/` directory. Current count: 400 tests (10 core, 80 runtime, 59 ui, 31 3d, 15 testing, 205 examples).

Prefer pure/deterministic tests over terminal smoke tests. Test layout planning, state transforms, math functions, and data structures directly.

## Native Library Resolution

The FFI shim resolves the native `.so`/`.dylib`/`.dll` in order:
1. Submodule build: `native/opentui-zig/packages/core/src/zig/lib/<target>/`
2. Submodule fallback: `.../zig-out/lib/`
3. NPM prebuilt: `node_modules/@opentui/core-<platform>-<arch>/`

If missing, run `npm install` inside `packages/opentui_core/`.
