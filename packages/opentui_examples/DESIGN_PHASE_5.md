# Phase 5 Design — 3D, Physics, Showcase, and Testing Foundation

**Status: planned.**

Phase 5 is the final example phase. It has two distinct halves:

1. **Showcase demos** (6 of 8) that push the rendering and composition model into
   3D graphics, physics simulation, and full-ecosystem composition.
2. **Testing foundation** that hardens the ecosystem for long-term package growth.

The central design question: phases 1–4 proved that FP composability works for
2D TUI rendering, keyboard/mouse interaction, text tooling, animation, and
framebuffer compositing. Can the same `fn(state) -> state` / `fn(state) -> view`
pattern extend to 3D scenes and physics simulations without collapsing into
imperative JS code?

---

## The eight demos

| Demo | Domain | Core capability needed |
|---|---|---|
| `shader-cube-demo` | Rotating 3D cube with custom shaders | 3D scene graph, shader pipeline, camera |
| `fractal-shader-demo` | Mandelbrot/Julia fractal rendered per-cell | Per-cell math shader, color mapping |
| `lights-phong-demo` | Lit 3D scene with Phong shading model | 3D lighting, materials, normals |
| `draggable-three-demo` | 3D object with mouse drag interaction | 3D hit testing, drag state, camera projection |
| `physx-planck-2d-demo` | 2D physics with rigid bodies (Planck.js) | Physics world step, body state extraction |
| `physx-rapier-2d-demo` | 2D physics with rigid bodies (Rapier) | Physics world step, body state extraction |
| `golden-star-demo` | Showcase: animated golden star composition | Full pipeline: animation + framebuffer + color math |
| `opentui-demo` | Showcase: multi-panel ecosystem overview | Full ecosystem composition, all capabilities |

---

## Strategic decision: where does 3D live?

The native Zig library exposes **no** 3D APIs. All 3D in the upstream TypeScript
demos comes from JS-side constructs:

- `three` (Three.js) — scene graph, cameras, materials, lights, shaders
- `ThreeCliRenderer` — bridges Three.js output into terminal framebuffers
- Shader programs as GLSL strings processed through Three.js

This means 3D in OpenTUI is fundamentally a **JS-side runtime**, not a native
capability. We have three design options:

### Option A: `opentui_3d` package with full Gleam bindings

Create a dedicated package wrapping Three.js concepts:

```gleam
type Scene
type Camera
type Mesh
type Material
type Light

fn create_scene() -> Scene
fn add_mesh(scene, geometry, material, position) -> Mesh
fn set_camera(scene, fov, aspect, near, far) -> Camera
fn render_to_buffer(scene, camera, buffer) -> Nil
```

**Pros**: Full FP control, type-safe scene composition.
**Cons**: Massive binding surface. Three.js has hundreds of types. Wrapping even
the subset needed for 4 demos requires ~30 FFI functions. The abstraction would
be a thin wrapper over JS objects with no real FP benefit — a `Scene` is
inherently mutable state.

### Option B: Thin JS shim (phase 4 approach, extended)

Each demo has its own JS init/tick/destroy functions. Gleam owns the event loop,
title bar, status bar, and key handling. JS owns the 3D internals.

**Pros**: Pragmatic, fast to implement, matches phase 4 sprite demos.
**Cons**: 3D logic isn't composable from Gleam. Each demo is a monolith.

### Option C: Pure TUI rendering with mathematical models

Skip Three.js entirely. Implement 3D concepts as pure Gleam math:

```gleam
type Vec3 { Vec3(x: Float, y: Float, z: Float) }
type Mat4  // 4x4 matrix as 16 Floats
type Camera { Camera(position: Vec3, target: Vec3, fov: Float) }

fn project(point: Vec3, camera: Camera, viewport: #(Int, Int)) -> #(Int, Int)
fn rotate_y(v: Vec3, angle: Float) -> Vec3
fn phong_shade(normal: Vec3, light_dir: Vec3, view_dir: Vec3) -> Float
```

Each "3D demo" renders by projecting 3D points to 2D terminal coordinates and
drawing with `buffer.set_cell`. No Three.js dependency. The entire pipeline is
pure Gleam.

**Pros**: Maximally FP. Zero JS dependencies. Tests can verify projection math,
shading calculations, physics integration. Demonstrates that terminal graphics
don't need a GPU — just math.
**Cons**: No real shaders, no textures, limited visual fidelity. But for a TUI,
ASCII/Unicode art with correct 3D projection is arguably more impressive than a
Three.js framebuffer dump.

### Recommendation: Option C

Option C is the right call for the Gleam ecosystem. Here's why:

1. **It's our edge.** "3D rendering as pure functions" is something no other TUI
   framework does. Phase 4 already proved the concept with bounce physics — phase 5
   extends it to 3D projection and lighting.

2. **It's testable.** Every function in the 3D pipeline can be unit tested:
   `project(Vec3(1,0,5), camera, #(80,24))` returns `#(45, 12)`. Try testing
   a Three.js scene graph.

3. **No npm dependency.** The upstream demos need `three` (2MB+ npm package).
   Our demos need nothing beyond `gleam/float` and `gleam/int`.

4. **It composes.** A `Camera` is data. A scene is `List(#(Vec3, String))` —
   points with characters. Lighting is `fn(Vec3, Vec3) -> Float`. These compose
   with our existing `Timeline`, `Layer`, `Vec2` abstractions naturally.

The physics demos (Planck/Rapier) follow the same logic: implement a simple 2D
physics step function in pure Gleam rather than wrapping JS physics engines.

---

## Core/Runtime/UI requirements

### `opentui_core` — No new FFI bindings needed

Phase 5 adds no new native capabilities. Everything builds on the existing
buffer, framebuffer, and animation infrastructure from phases 1–4.

### `opentui_runtime` — New pure modules

#### `math3d.gleam` (new, pure — no FFI)

```gleam
pub type Vec3 { Vec3(x: Float, y: Float, z: Float) }

pub fn vec3_add(a: Vec3, b: Vec3) -> Vec3
pub fn vec3_sub(a: Vec3, b: Vec3) -> Vec3
pub fn vec3_scale(v: Vec3, s: Float) -> Vec3
pub fn vec3_dot(a: Vec3, b: Vec3) -> Float
pub fn vec3_cross(a: Vec3, b: Vec3) -> Vec3
pub fn vec3_normalize(v: Vec3) -> Vec3
pub fn vec3_length(v: Vec3) -> Float

pub fn rotate_x(v: Vec3, angle: Float) -> Vec3
pub fn rotate_y(v: Vec3, angle: Float) -> Vec3
pub fn rotate_z(v: Vec3, angle: Float) -> Vec3

/// Project a 3D point to 2D screen coordinates.
/// Returns #(screen_x, screen_y, depth) where depth is for z-sorting.
pub fn project(
  point: Vec3,
  camera_pos: Vec3,
  camera_target: Vec3,
  fov: Float,
  viewport_w: Int,
  viewport_h: Int,
) -> #(Float, Float, Float)
```

Tests: vec3 arithmetic identities, rotation by 0/90/180/360 degrees, projection
of known points (center of viewport, corners, behind camera).

#### `lighting.gleam` (new, pure — no FFI)

```gleam
pub type Light {
  DirectionalLight(direction: Vec3, color: #(Float, Float, Float), intensity: Float)
  PointLight(position: Vec3, color: #(Float, Float, Float), intensity: Float, range: Float)
  AmbientLight(color: #(Float, Float, Float), intensity: Float)
}

/// Phong shading: returns intensity multiplier [0.0, 1.0+].
pub fn phong(
  normal: Vec3,
  light_dir: Vec3,
  view_dir: Vec3,
  shininess: Float,
) -> Float

/// Compute total illumination from a list of lights at a surface point.
pub fn illuminate(
  lights: List(Light),
  position: Vec3,
  normal: Vec3,
  view_pos: Vec3,
  shininess: Float,
) -> #(Float, Float, Float)
```

Tests: Phong with light directly facing normal returns max intensity. Light
perpendicular to normal returns near-zero. Ambient light always contributes.

#### `physics2d.gleam` (new, pure — no FFI)

```gleam
pub type Body {
  Body(
    position: Vec2,
    velocity: Vec2,
    angle: Float,
    angular_velocity: Float,
    mass: Float,
    restitution: Float,
    shape: Shape,
  )
}

pub type Shape {
  Circle(radius: Float)
  Rectangle(width: Float, height: Float)
}

pub type World {
  World(
    bodies: List(Body),
    gravity: Vec2,
    bounds: #(Float, Float, Float, Float),  // min_x, min_y, max_x, max_y
  )
}

/// Step the physics world by dt seconds.
pub fn step(world: World, dt: Float) -> World

/// Apply gravity, integrate velocity into position.
pub fn integrate(body: Body, gravity: Vec2, dt: Float) -> Body

/// Bounce bodies off world bounds.
pub fn constrain(body: Body, bounds: #(Float, Float, Float, Float)) -> Body

/// Check and resolve circle-circle collision.
pub fn collide_circles(a: Body, b: Body) -> #(Body, Body)
```

Tests: Gravity accelerates downward. A body at rest on the floor stays put.
Two circles colliding separate with correct velocities. Bounds enforcement
reflects velocity.

This is deliberately simple — not a full physics engine, but enough to render
convincing 2D simulations. The Planck demo and Rapier demo both use this same
`physics2d` module with different parameter presets (different restitution,
gravity, body counts), demonstrating that the "engine" is the same pure
function with different initial data.

### `opentui_ui` — No changes needed

The Element tree is sufficient for all phase 5 rendering. 3D scenes render
through `buffer.set_cell` (buffer-based approach), not through Element trees.

---

## Examples infrastructure

### `phase5_model.gleam` (new, pure)

Domain types and functions for all 8 demos:

```gleam
// 3D scene primitives
pub type Vertex { Vertex(position: Vec3, normal: Vec3) }
pub type Face { Face(v0: Int, v1: Int, v2: Int) }
pub type Mesh3D { Mesh3D(vertices: List(Vertex), faces: List(Face)) }

// Predefined meshes
pub fn cube_mesh() -> Mesh3D     // unit cube centered at origin
pub fn star_mesh() -> Mesh3D     // 5-pointed star extruded

// Fractal
pub fn mandelbrot(cx: Float, cy: Float, max_iter: Int) -> Int
pub fn julia(zx: Float, zy: Float, cx: Float, cy: Float, max_iter: Int) -> Int
pub fn fractal_color(iterations: Int, max_iter: Int) -> #(Float, Float, Float, Float)

// Scene description as pure data
pub type SceneObject {
  SceneObject(
    mesh: Mesh3D,
    position: Vec3,
    rotation: Vec3,   // euler angles
    scale: Float,
    color: #(Float, Float, Float, Float),
  )
}

pub fn transform_vertex(v: Vec3, obj: SceneObject) -> Vec3
  // apply scale → rotate → translate

// Drag interaction state
pub type DragState {
  Idle
  Dragging(start_x: Int, start_y: Int, obj_start_rotation: Vec3)
}

pub fn update_drag(state: DragState, mouse_x: Int, mouse_y: Int) -> Vec3
  // returns new rotation based on mouse delta

// Showcase composition
pub type DemoPanel {
  DemoPanel(id: String, title: String, x: Int, y: Int, w: Int, h: Int)
}

pub fn showcase_layout(panels: List(DemoPanel), selected: Int) -> List(DemoPanel)
```

### `phase5_state.gleam` — reuse phase4_state

FloatCell from phase 4 is sufficient. No new cell types needed.

### Tests required

`opentui_phase5_model_test.gleam`:
- `cube_mesh` returns 8 vertices and 12 faces
- `mandelbrot` at origin returns max_iter (inside set)
- `mandelbrot` far from origin returns low iteration count
- `julia` boundary point returns intermediate count
- `fractal_color` at 0 iterations returns dark, at max returns bright
- `transform_vertex` with identity rotation returns position + offset
- `update_drag` from Idle returns zero rotation
- `showcase_layout` preserves panel count

---

## Demo implementation strategy

### Group A — Pure 3D rendering (no external dependencies)

#### `shader_cube_demo`

A rotating wireframe cube rendered by projecting 3D vertices to 2D terminal
coordinates. Each edge is drawn as a line of ASCII characters between projected
endpoints. The "shader" is a per-vertex color function based on vertex normal
dot product with a light direction.

Uses `run_animated_demo`. `on_tick` advances rotation angle. `draw_body`
projects all vertices through `math3d.project`, draws edges with
`buffer.set_cell`, and applies Phong-like shading to determine character
brightness (` ` `.` `:` `*` `#` `@` from dark to bright).

**FP pattern**: Scene is `SceneObject` data. Rotation is a Float that advances
each tick. Projection is a pure function. Shading is a pure function. The entire
3D pipeline is `rotate → project → shade → draw` with no mutable state beyond
the angle cell.

#### `fractal_shader_demo`

Mandelbrot set rendered per-cell across the terminal viewport. Each cell maps
to a complex number, `mandelbrot(cx, cy, max_iter)` returns iteration count,
`fractal_color` maps count to an RGBA color. The viewport pans slowly over time
to show different regions of the fractal.

Uses `run_animated_demo`. `on_tick` advances the viewport center. `draw_body`
iterates over every `(x, y)` cell, computes the fractal value, and sets the
cell color.

**FP pattern**: `mandelbrot` is the purest function imaginable — it takes two
floats and returns an int. The entire demo is a map over `(x, y) -> color`.

#### `lights_phong_demo`

A sphere (approximated as a grid of surface points) lit by one directional
light and one ambient light. The Phong shading model computes diffuse and
specular components per surface point. The light rotates around the sphere
over time.

Uses `run_animated_demo`. The sphere is a list of `(Vec3, Vec3)` pairs
(position, normal) precomputed once. Each frame, the light direction rotates,
and `lighting.phong` is called per-point to determine brightness.

**FP pattern**: The scene is static data. Only the light moves. Rendering is
`list.map(surface_points, fn(p) { shade(p, light_dir) })`.

#### `draggable_three_demo`

A 3D object (cube or tetrahedron) that can be rotated by mouse drag. Click
starts tracking, drag updates rotation, release commits. The rotation state
is stored as `Vec3` (euler angles) in FloatCells.

Uses `run_event_demo_with_setup` (needs mouse). `DragState` tracks whether
a drag is active. `update_drag` computes new rotation from mouse delta.

**FP pattern**: `DragState` is an ADT (Idle | Dragging). The transition is
`fn(DragState, MouseEvent) -> #(DragState, Vec3)`. The 3D rendering reuses
`math3d.project` and `lighting.phong`.

### Group B — Physics simulations (pure Gleam, no JS engines)

#### `physx_planck_2d_demo`

5–8 circles bouncing in a box with gravity. Uses `physics2d.step` to advance
the simulation. Rendered by mapping each body's position to screen coordinates
and drawing circles with `buffer.set_cell`. Shows velocity vectors as arrows.

Preset: high gravity (9.8), low restitution (0.6), small circles.

#### `physx_rapier_2d_demo`

Same `physics2d` module but with different presets: mixed circles and
rectangles, higher restitution (0.9), moderate gravity. Shows that the same
pure physics step function produces different visual behavior with different
initial data — not a different engine.

Both demos use `run_animated_demo` with `physics2d.step` in `on_tick`.

**FP pattern**: The physics world is data. `step(world, dt)` returns a new
world. No mutation, no callbacks, no event system. The view reads body positions
and draws them. This is the FP composability edge at its clearest — a physics
"engine" is just `fn(World, Float) -> World`.

### Group C — Showcase compositions

#### `golden_star_demo`

An animated golden star that combines:
- `math3d` — 3D star mesh projected to 2D
- `animation.Timeline` — rotation and scale tweens
- `framebuffer` — composited onto a pattern background
- `lighting.phong` — golden Phong shading
- `phase4_model.hue_to_rgb` — subtle hue cycling on the star edges

This is a composition demo, not a new capability demo. It validates that
all the phase 4 and 5 pure modules compose cleanly.

#### `opentui_demo`

The ecosystem showcase. A multi-panel layout showing:
- Panel 1: Live stats (frame count, elapsed time, body count from physics)
- Panel 2: Mini fractal viewport (small mandelbrot rendering)
- Panel 3: Animated timeline progress bars
- Panel 4: Unicode grapheme sample
- Panel 5: Spinning 3D wireframe cube (small viewport)
- Panel 6: Architecture summary text

Tab cycles panel focus. Each panel draws its content independently using
the respective module (`physics2d`, `math3d`, `animation`, `grapheme`).

**FP pattern**: The showcase is pure composition. Each panel is a
`fn(Buffer, x, y, w, h, state) -> Nil` draw function. The layout is a
`List(DemoPanel)`. Adding a panel = adding an entry to the list and a
draw function.

---

## Testing strategy

### New runtime module tests

| Module | Test count (est.) | Key assertions |
|---|---|---|
| `math3d` | 15–20 | Vec3 arithmetic identities, rotation periodicity, projection center/edges/behind-camera |
| `lighting` | 8–12 | Phong boundaries (facing=max, perpendicular=0, behind=0), ambient always adds, multi-light accumulation |
| `physics2d` | 10–15 | Gravity integration, bounds reflection, circle-circle collision, energy conservation approximation |

### New examples model tests

| Module | Test count (est.) | Key assertions |
|---|---|---|
| `phase5_model` | 12–15 | Mesh vertex/face counts, mandelbrot convergence/divergence, fractal color boundaries, transform identity, drag state transitions |

### Existing test enforcement

Current test counts across the ecosystem:

| Package | Tests |
|---|---|
| opentui_core | 10 |
| opentui_runtime | 52 |
| opentui_ui | 17 |
| opentui_examples | 79 |
| **Total** | **158** |

Phase 5 target: **200+ tests** across the ecosystem.

### FP invariants to enforce through tests

The testing strategy isn't just about coverage — it's about enforcing the FP
foundation that makes this ecosystem different from imperative TUI frameworks.

#### 1. Purity tests

Every pure function should be testable without any FFI setup:

```gleam
// This must work with zero initialization:
pub fn vec3_cross_test() {
  let result = math3d.vec3_cross(Vec3(1.0, 0.0, 0.0), Vec3(0.0, 1.0, 0.0))
  result |> should.equal(Vec3(0.0, 0.0, 1.0))
}
```

If a test needs `renderer.create` or `buffer.create` to run, the function
under test is **not pure** and should be in a wrapper module, not in the
model.

#### 2. Composition tests

Verify that composing pure functions produces correct results:

```gleam
// rotate then project should produce known coordinates
pub fn rotate_then_project_test() {
  let v = Vec3(1.0, 0.0, 0.0)
  let rotated = math3d.rotate_y(v, 90.0)
  // After 90° Y rotation, (1,0,0) becomes (0,0,-1)
  let #(sx, sy, _depth) = math3d.project(rotated, ...)
  // Verify screen coordinates are within viewport
}
```

#### 3. Roundtrip tests

Verify that operations invert correctly:

```gleam
pub fn rotation_360_is_identity_test() {
  let v = Vec3(3.0, 4.0, 5.0)
  let rotated = math3d.rotate_y(v, 360.0)
  assert_vec3_near(rotated, v)
}

pub fn physics_step_zero_dt_is_identity_test() {
  let world = create_test_world()
  let stepped = physics2d.step(world, 0.0)
  stepped.bodies |> should.equal(world.bodies)
}
```

#### 4. Invariant tests

Verify that physical laws hold:

```gleam
pub fn gravity_only_affects_y_velocity_test() {
  let body = Body(position: Vec2(5.0, 5.0), velocity: Vec2(3.0, 0.0), ...)
  let stepped = physics2d.integrate(body, Vec2(0.0, -9.8), 1.0)
  // x velocity unchanged
  stepped.velocity.x |> should.equal(3.0)
  // y velocity changed by gravity
  assert_near(stepped.velocity.y, -9.8)
}
```

---

## Implementation order

```
Step 1:  opentui_runtime  — math3d.gleam + tests (pure, no FFI)
Step 2:  opentui_runtime  — lighting.gleam + tests (pure, no FFI)
Step 3:  opentui_runtime  — physics2d.gleam + tests (pure, no FFI)
Step 4:  opentui_examples — phase5_model.gleam + tests
Step 5:  opentui_examples — shader_cube_demo + fractal_shader_demo
Step 6:  opentui_examples — lights_phong_demo + draggable_three_demo
Step 7:  opentui_examples — physx_planck_2d_demo + physx_rapier_2d_demo
Step 8:  opentui_examples — golden_star_demo + opentui_demo
Step 9:  opentui_examples — catalog.gleam + README.md update
Step 10: all packages     — final test suite verification (target: 200+)
```

Steps 1–3 are pure Gleam modules with zero FFI — they can be developed and
tested independently. This is the fastest part.

Steps 5–8 are the demos. Each builds on the runtime modules from steps 1–3
and the model from step 4.

Step 10 is the quality gate: verify all tests pass, count exceeds 200,
and every pure function is tested without FFI initialization.

---

## What makes this phase different from phase 4

Phase 4 introduced **time** and **spatial composition** as new dimensions.
Phase 5 introduces **mathematical rendering** — the idea that 3D graphics,
lighting, and physics are just math functions that produce terminal output.

The key insight: in a GPU-based renderer, shaders are opaque programs that
run on dedicated hardware. In a TUI renderer, "shaders" are just
`fn(x, y) -> color` — pure functions called per cell. Phong lighting is
`fn(normal, light_dir) -> Float`. Fractal rendering is
`fn(cx, cy) -> Int`. Physics is `fn(world, dt) -> world`.

This is the culmination of the FP composability thesis: every capability
that seems to require imperative machinery (3D engines, physics engines,
shader compilers) can be expressed as pure functions over algebraic data
when the output medium is a terminal grid.

---

## Risk areas

1. **Performance** — Per-cell fractal computation at 80×24 = 1920 cells per
   frame at 30fps = 57,600 `mandelbrot` calls per second. Each call iterates
   up to `max_iter` times. With `max_iter=50`, that's up to 2.88M float
   operations per second in Gleam/JS. Should be fine on modern hardware, but
   worth profiling. Mitigation: reduce `max_iter` or viewport size if needed.

2. **3D projection accuracy** — Integer terminal coordinates mean we lose
   sub-cell precision. Wireframe edges will look jagged. Mitigation: use
   Unicode block characters (▀▄█░▒▓) for sub-cell rendering, and accept
   that TUI 3D is inherently low-resolution.

3. **Physics stability** — Simple Euler integration can explode with large
   `dt` or high velocities. Mitigation: clamp `dt` to 50ms max, use
   substeps if needed (2× step at half dt).

4. **Mouse interaction in draggable demo** — The event loop must handle
   mouse events, which requires `renderer.enable_mouse`. Phase 2 already
   proved this works (`mouse_interaction_demo`), so risk is low.

5. **Showcase demo complexity** — `opentui_demo` draws 6 independent panels,
   each with its own rendering logic. At 30fps, this means 6 draw functions
   per frame. The framebuffer composition approach from phase 4 helps (each
   panel renders to its own framebuffer, then composites), but the total
   draw cost is still higher than any previous demo. Mitigation: keep panel
   viewports small and reduce update frequency for expensive panels
   (fractal updates every 5th frame, physics updates every frame).

---

## Reuse from earlier phases

- `phase4_model.gleam` — Vec2, bounce, lerp_float, lerp_color, hue_to_rgb, pattern_char, clamp_float
- `phase4_state.gleam` — FloatCell (sufficient for all phase 5 state)
- `phase2_state.gleam` — IntCell, BoolCell
- `phase2_model.gleam` — parse_key, clamp
- `common.gleam` — run_animated_demo, run_event_demo_with_setup, draw_panel, panel, color constants
- `animation.gleam` — Timeline, Tween, tick, value, ease_in_out, ease_out_bounce
- `framebuffer.gleam` — create, destroy, draw_onto, draw_region
- `buffer.gleam` — set_cell, fill_rect, draw_text
