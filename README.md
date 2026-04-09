# opentui-gleam

This repository is a **Gleam-first OpenTUI monorepo** that ports and grows the OpenTUI ecosystem in a language better suited to the project’s long-term direction: typed functional composition, explicit data flow, and reusable pure abstractions. We use Gleam because the repository is not just binding a native library; it is trying to build a composable terminal UI stack where UI trees, interaction reducers, layout planning, animation state, and rendering plans can be modeled as testable data before the final terminal side effect.

## Package layout

```text
packages/
  opentui_core/
  opentui_runtime/
  opentui_ui/
  opentui_testing/
  opentui_3d/
  opentui_examples/
```

### `packages/opentui_core`

Owns the low-level native bridge:

- `opentui/ffi.gleam`
- `opentui/ffi_shim.js`
- native resolution logic
- native fallback `package.json`
- `scripts/build-native.sh`

### `packages/opentui_runtime`

Owns ergonomic Gleam wrappers over the core layer:

- `opentui/runtime.gleam`
- `opentui/renderer.gleam`
- `opentui/buffer.gleam`
- `opentui/edit_buffer.gleam`
- `opentui/text.gleam`
- `opentui/types.gleam`

### `packages/opentui_ui`

Owns the declarative UI layer:

- `opentui/ui.gleam`
- pure element ADTs
- single-pass rendering from UI data into buffer calls
- pure helpers like tree folding and serialization

### `packages/opentui_testing`

Owns reusable testing support for pure UI trees and widget/state assertions:

- `opentui/testing.gleam`
- synthetic key and mouse helpers
- element tree and layout-plan inspection
- widget trace helpers

### `packages/opentui_3d`

Owns optional 3D-specific pure planning and math helpers:

- `opentui/math3d.gleam`
- `opentui/lighting.gleam`
- `opentui/wireframe.gleam`

### `packages/opentui_examples`

Owns runnable demos and the catalog/help entrypoint:

- `opentui/catalog.gleam`
- `opentui/examples/*`
- `opentui_examples.gleam`

## Local dependency pattern

Each package has its own `gleam.toml` and uses local path dependencies where needed.

Current dependency flow:

- `opentui_runtime` → `opentui_core`
- `opentui_ui` → `opentui_core`, `opentui_runtime`
- `opentui_testing` → `opentui_runtime`, `opentui_ui`
- `opentui_3d` → `opentui_runtime`
- `opentui_examples` → `opentui_core`, `opentui_runtime`, `opentui_ui`, `opentui_3d`

## Getting started

After cloning, the native `libopentui` shared library must be available before anything will run. There are two ways to get it.

### Prerequisites

- [Gleam](https://gleam.run) >= 1.15
- [Bun](https://bun.sh) (the JS runtime used by the Gleam JS target)
- One of the two native library options below

### Option A — npm prebuilt (easiest)

Prebuilt binaries are published to npm. Install them inside `opentui_core`:

```bash
cd packages/opentui_core
npm install
```

This pulls the platform-specific `@opentui/core-<platform>-<arch>` package into `packages/opentui_core/node_modules/`. The FFI shim knows how to find the library there, even when running from other packages like `opentui_examples`.

### Option B — build from submodule

If you need a newer build or your platform has no prebuilt package, build the Zig shared library from source. This requires [Zig](https://ziglang.org) 0.15.2.

```bash
git submodule update --init --recursive
./scripts/build-native.sh
```

The script runs `zig build` inside `native/opentui-zig/packages/core/src/zig/` and places the output under `.../lib/<arch>-<os>/libopentui.so` (or `.dylib` / `.dll`).

### Build and test

Once the native library is available through either option:

```bash
./scripts/build-all.sh   # builds all six packages
./scripts/test-all.sh    # runs all tests
```

`build-all.sh` will automatically run `build-native.sh` if the submodule is present and no npm prebuilt is installed.

You can also build or test a single package:

```bash
cd packages/opentui_core && gleam test
cd packages/opentui_runtime && gleam test
```

### Run demos

```bash
./scripts/run-example.sh catalog   # list all demos
./scripts/run-example.sh editor    # run a specific demo
```

Or directly:

```bash
cd packages/opentui_examples && gleam run -m opentui/examples/editor
```

Available root-level example names:

- `catalog`
- any example id supported by `./scripts/run-example.sh`, including the phase demos and showcase demos

For example:

- `editor`
- `text-selection-demo`
- `sprite-animation-demo`
- `sprite-particle-generator-demo`
- `physx-planck-2d-demo`
- `physx-rapier-2d-demo`
- `draggable-three-demo`
- `opentui-demo`

The examples package is no longer just a small bootstrap set. It now contains the full phased demo catalog and is effectively the runnable proof that the lower-level `core` / `runtime` / `ui` packages are covering the intended OpenTUI surface area. For the full current list and phase breakdown, see `packages/opentui_examples/README.md` or run `./scripts/run-example.sh catalog`.

## Publishing direction

This layout is designed so each package can become independently publishable to Hex.pm with its own:

- `gleam.toml`
- source tree
- tests
- repository path metadata
- versioning/tag prefix

See `ROADMAP.md` for the longer-term package plan.

## FP composability follow-up checklist

The recent demo parity passes improved the repository by pushing more logic into
pure demo-local model modules with tests, while keeping imperative rendering at
the final TUI boundary. The next step is to consolidate the reusable parts of
those patterns into core/runtime/ui layers in a more composable and testable
way.

- [x] Add a pure draw-plan layer in `packages/opentui_ui` so demos and widgets
  can build `line` / `rect` / `cell` / `text` / layered scene data first, then
  lower it into buffer calls in one final pass.
- [x] Add reusable pure interaction reducers in `packages/opentui_ui` for mouse
  dragging, hit testing, bounded movement, and viewport state transitions.
- [x] Add pure timeline / animation helpers in `packages/opentui_ui` or
  `packages/opentui_runtime` for common `tick` / `toggle` / `pause` /
  auto-advance / rate-limited spawn patterns.
- [x] Consolidate repeated demo-local state machine shapes into reusable,
  testable reducer-style helpers while keeping package dependencies flowing
  downward.
- [x] Evaluate whether wireframe / projected-scene planning should live in
  `packages/opentui_ui` as a pure intermediate representation, with clipping and
  raster planning tested independently from rendering.
- [x] Add tests for any new pure planning/reducer layers before migrating demos
  onto them, so composability improvements do not regress the current examples.
- [x] Migrate one existing demo at a time onto the new pure abstractions and run
  the full test suite after each step rather than batching a large refactor.
