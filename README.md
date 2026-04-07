# opentui-gleam

This repository is now structured as a **Gleam monorepo** with multiple self-contained packages that can be evolved toward independent Hex.pm publication.

## Package layout

```text
packages/
  opentui_core/
  opentui_runtime/
  opentui_ui/
  opentui_examples/
```

### `packages/opentui_core`

Owns the low-level native bridge:

- `opentui/ffi.gleam`
- `opentui/runtime.gleam`
- `opentui/ffi_shim.js`
- native resolution logic
- native fallback `package.json`
- `scripts/build-native.sh`

### `packages/opentui_runtime`

Owns ergonomic Gleam wrappers over the core layer:

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
- `opentui_examples` → `opentui_core`, `opentui_runtime`, `opentui_ui`

## Native library resolution

`opentui_core` resolves the native library in this order:

1. submodule build output under `native/opentui-zig/packages/core/src/zig/lib/<target>/`
2. submodule fallback under `.../zig-out/lib/`
3. platform-native npm package under `node_modules/@opentui/core-<platform>-<arch>/`

Inside `packages/opentui_core`, run:

```bash
npm install
```

to install the matching optional prebuilt native package for the current machine.

## Common commands

Build everything:

```bash
./scripts/build-all.sh
```

Test everything:

```bash
./scripts/test-all.sh
```

Run the examples package catalog:

```bash
(cd packages/opentui_examples && gleam run)

# or from the project root
./scripts/run-example.sh catalog
```

Run a specific demo:

```bash
(cd packages/opentui_examples && gleam run -m opentui/examples/editor)

# or from the project root
./scripts/run-example.sh editor
```

Available root-level example names:

- `catalog`
- `editor`
- `terminal-title`
- `text-wrap`
- `text-truncation`

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
- [ ] Consolidate repeated demo-local state machine shapes into reusable,
  testable reducer-style helpers while keeping package dependencies flowing
  downward.
- [x] Evaluate whether wireframe / projected-scene planning should live in
  `packages/opentui_ui` as a pure intermediate representation, with clipping and
  raster planning tested independently from rendering.
- [ ] Add tests for any new pure planning/reducer layers before migrating demos
  onto them, so composability improvements do not regress the current examples.
- [ ] Migrate one existing demo at a time onto the new pure abstractions and run
  the full test suite after each step rather than batching a large refactor.
