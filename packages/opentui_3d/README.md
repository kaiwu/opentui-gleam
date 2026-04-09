# opentui_3d

Optional 3D-oriented helpers for `opentui-gleam`.

This package isolates the more specialized rendering/math pieces from the main
runtime and UI layers so the core publishable story stays lighter.

## Current surface

- `opentui/math3d.gleam` for vector and projection helpers
- `opentui/lighting.gleam` for simple lighting calculations
- `opentui/wireframe.gleam` for pure mesh projection and raster planning

## Intended role

This package should stay optional. It is a good home for advanced 3D-oriented
capabilities that are valuable for showcase demos but should not burden the
main runtime package surface.
