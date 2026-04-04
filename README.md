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
