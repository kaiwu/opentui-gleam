# opentui_runtime

Ergonomic Gleam wrappers over `opentui_core`.

This package provides the main runtime-facing APIs for:

- app lifecycle/orchestration helpers
- loop helpers above the raw FFI boundary
- renderer lifecycle
- buffer drawing
- edit buffer operations
- pure text helpers

Key modules now include:

- `opentui/app.gleam`
- `opentui/runtime.gleam`
- `opentui/renderer.gleam`
- `opentui/buffer.gleam`
- `opentui/input.gleam`
- `opentui/editor_view.gleam`
- `opentui/text_buffer.gleam`
- `opentui/syntax_style.gleam`

## Future async APIs

If this repository needs Promise-like or asynchronous behavior later, it will most likely belong in `opentui_runtime`, not `opentui_core`.

Examples of likely future async runtime surfaces:

- renderer creation/setup flows that wait for terminal capability detection
- palette detection
- testing helpers that wait for render-idle states or synthetic input timing
- plugin/runtime loading
- 3D, file-backed, or GPU-backed features

That means this package is the place to add higher-level async wrappers when we reach those capabilities, while keeping the low-level FFI package mechanical and mostly synchronous.
