# opentui_core

Low-level Gleam bindings for OpenTUI.

This package owns:

- raw FFI declarations
- the Bun FFI shim
- native library resolution

It is intended to stay small and mechanical.

## Sync vs async boundary

The current raw OpenTUI native surface bound here is intentionally **synchronous**.

That matches the upstream low-level Zig/FFI layer: buffer operations, edit-buffer operations, editor-view operations, syntax-style registration, and related native calls are direct synchronous ABI calls.

Upstream TypeScript does have `async` / `Promise` APIs, but those mostly belong to higher JS-managed layers such as:

- renderer initialization and terminal setup orchestration
- terminal capability and palette probing
- testing helpers
- runtime plugin loading
- 3D / file / GPU-backed features

So if an upstream API is async, do **not** assume `opentui_core` should mirror it automatically. First verify whether the async boundary is truly in the native ABI or only in the higher runtime/tooling layer.

Default rule:

- raw native bridge in `opentui_core` → keep synchronous unless the underlying ABI truly requires async behavior
- higher orchestration APIs → belong in `opentui_runtime` or later packages
