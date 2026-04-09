# opentui_testing

Reusable testing helpers for the `opentui-gleam` ecosystem.

This package exists to make pure UI trees, widget state machines, and layout
plans testable without needing to boot a terminal renderer for every check.

## Current surface

- synthetic key helpers such as `arrow_up`, `tab`, `backspace`, and `char`
- synthetic mouse helpers such as `mouse_press`, `mouse_release`, and scroll
- event driving helpers like `apply_events` and `apply_keys`
- element tree inspection with `count_elements`, `element_texts`, and `tree_contains_text`
- layout plan inspection with `find_nodes`, `layout_bounds`, and `plan_snapshot`
- frame-style snapshots via `snapshot`
- widget tracing via `trace_widget`

## Intended role

`opentui_testing` is the package-level answer to the roadmap's testing story:
freeze pure semantics first, then rely on a smaller number of runtime smoke
tests for the terminal-facing edge.
