# opentui_ui

Declarative, composable UI data structures and render helpers for OpenTUI in Gleam.

This package is where the project starts turning imperative buffer drawing into pure UI trees that are rendered in a single pass.

## Current surface

- `opentui/ui.gleam` for element trees, layout planning, and bounded rendering
- `opentui/widgets.gleam` for scroll, input, select, tab, and code-view helpers
- `opentui/interaction.gleam` for focus and click-region reducers
- `opentui/draw_plan.gleam` for pure draw-op planning
- `opentui/timeline.gleam`, `simulation.gleam`, and `frame_playback.gleam` for pure state helpers

The package is still intentionally lightweight, but it now owns reusable widget
and layout semantics rather than just tree serialization.
