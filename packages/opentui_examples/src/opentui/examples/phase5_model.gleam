import gleam/float
import gleam/int
import gleam/list
import opentui/math3d.{type Vec3, Vec3}

// ---------------------------------------------------------------------------
// Mesh types
// ---------------------------------------------------------------------------

pub type Vertex {
  Vertex(position: Vec3, normal: Vec3)
}

pub type Edge {
  Edge(a: Int, b: Int)
}

pub type Mesh3D {
  Mesh3D(vertices: List(Vec3), edges: List(Edge))
}

// ---------------------------------------------------------------------------
// Predefined meshes
// ---------------------------------------------------------------------------

/// Unit cube centered at origin with 12 wireframe edges.
pub fn cube_mesh() -> Mesh3D {
  let s = 0.5
  let vertices = [
    Vec3(0.0 -. s, 0.0 -. s, 0.0 -. s),  // 0: left  bottom back
    Vec3(s, 0.0 -. s, 0.0 -. s),          // 1: right bottom back
    Vec3(s, s, 0.0 -. s),                  // 2: right top    back
    Vec3(0.0 -. s, s, 0.0 -. s),          // 3: left  top    back
    Vec3(0.0 -. s, 0.0 -. s, s),          // 4: left  bottom front
    Vec3(s, 0.0 -. s, s),                  // 5: right bottom front
    Vec3(s, s, s),                          // 6: right top    front
    Vec3(0.0 -. s, s, s),                  // 7: left  top    front
  ]
  let edges = [
    // Back face
    Edge(0, 1), Edge(1, 2), Edge(2, 3), Edge(3, 0),
    // Front face
    Edge(4, 5), Edge(5, 6), Edge(6, 7), Edge(7, 4),
    // Connecting edges
    Edge(0, 4), Edge(1, 5), Edge(2, 6), Edge(3, 7),
  ]
  Mesh3D(vertices, edges)
}

/// Pyramid mesh.
pub fn pyramid_mesh() -> Mesh3D {
  let s = 0.5
  let h = 0.7
  let vertices = [
    Vec3(0.0 -. s, 0.0 -. h, 0.0 -. s),  // 0: base left back
    Vec3(s, 0.0 -. h, 0.0 -. s),          // 1: base right back
    Vec3(s, 0.0 -. h, s),                  // 2: base right front
    Vec3(0.0 -. s, 0.0 -. h, s),          // 3: base left front
    Vec3(0.0, h, 0.0),                      // 4: apex
  ]
  let edges = [
    Edge(0, 1), Edge(1, 2), Edge(2, 3), Edge(3, 0),
    Edge(0, 4), Edge(1, 4), Edge(2, 4), Edge(3, 4),
  ]
  Mesh3D(vertices, edges)
}

pub fn vertex_count(mesh: Mesh3D) -> Int {
  list.length(mesh.vertices)
}

pub fn edge_count(mesh: Mesh3D) -> Int {
  list.length(mesh.edges)
}

// ---------------------------------------------------------------------------
// Fractal
// ---------------------------------------------------------------------------

/// Mandelbrot iteration count for complex point (cx, cy).
pub fn mandelbrot(cx: Float, cy: Float, max_iter: Int) -> Int {
  mandelbrot_loop(cx, cy, 0.0, 0.0, 0, max_iter)
}

fn mandelbrot_loop(
  cx: Float,
  cy: Float,
  zx: Float,
  zy: Float,
  i: Int,
  max_iter: Int,
) -> Int {
  case i >= max_iter {
    True -> max_iter
    False -> {
      let zx2 = zx *. zx
      let zy2 = zy *. zy
      case zx2 +. zy2 >. 4.0 {
        True -> i
        False -> {
          let new_zx = zx2 -. zy2 +. cx
          let new_zy = 2.0 *. zx *. zy +. cy
          mandelbrot_loop(cx, cy, new_zx, new_zy, i + 1, max_iter)
        }
      }
    }
  }
}

/// Julia set iteration for point (zx, zy) with constant (cx, cy).
pub fn julia(
  zx: Float,
  zy: Float,
  cx: Float,
  cy: Float,
  max_iter: Int,
) -> Int {
  julia_loop(zx, zy, cx, cy, 0, max_iter)
}

fn julia_loop(
  zx: Float,
  zy: Float,
  cx: Float,
  cy: Float,
  i: Int,
  max_iter: Int,
) -> Int {
  case i >= max_iter {
    True -> max_iter
    False -> {
      let zx2 = zx *. zx
      let zy2 = zy *. zy
      case zx2 +. zy2 >. 4.0 {
        True -> i
        False -> {
          let new_zx = zx2 -. zy2 +. cx
          let new_zy = 2.0 *. zx *. zy +. cy
          julia_loop(new_zx, new_zy, cx, cy, i + 1, max_iter)
        }
      }
    }
  }
}

/// Map iteration count to a color.
pub fn fractal_color(
  iterations: Int,
  max_iter: Int,
) -> #(Float, Float, Float, Float) {
  case iterations >= max_iter {
    True -> #(0.0, 0.0, 0.0, 1.0)
    False -> {
      let t = int.to_float(iterations) /. int.to_float(max_iter)
      let r = math3d.sin(t *. 5.0) *. 0.5 +. 0.5
      let g = math3d.sin(t *. 7.0 +. 1.0) *. 0.5 +. 0.5
      let b = math3d.sin(t *. 11.0 +. 2.0) *. 0.5 +. 0.5
      #(r, g, b, 1.0)
    }
  }
}

/// Map iteration count to an ASCII shade character.
pub fn fractal_char(iterations: Int, max_iter: Int) -> Int {
  case iterations >= max_iter {
    True -> 0x20  // space (inside set)
    False -> {
      let t = int.to_float(iterations) /. int.to_float(max_iter)
      let idx = float.truncate(t *. 9.0)
      shade_codepoint(idx)
    }
  }
}

fn shade_codepoint(index: Int) -> Int {
  case index {
    0 -> 0x2E  // .
    1 -> 0x3A  // :
    2 -> 0x2D  // -
    3 -> 0x3D  // =
    4 -> 0x2B  // +
    5 -> 0x2A  // *
    6 -> 0x23  // #
    7 -> 0x25  // %
    8 -> 0x40  // @
    _ -> 0x40  // @
  }
}

// ---------------------------------------------------------------------------
// Shading characters for 3D
// ---------------------------------------------------------------------------

/// Map a brightness value [0.0, 1.0] to an ASCII shade character.
pub fn shade_char(brightness: Float) -> Int {
  let clamped = float.min(float.max(brightness, 0.0), 1.0)
  let idx = float.truncate(clamped *. 7.0)
  case idx {
    0 -> 0x20   // space
    1 -> 0x2E   // .
    2 -> 0xB7   // ·
    3 -> 0x2B   // +
    4 -> 0x2A   // *
    5 -> 0x25   // %
    6 -> 0x23   // #
    _ -> 0x2588 // █
  }
}

// ---------------------------------------------------------------------------
// Sphere surface points
// ---------------------------------------------------------------------------

/// Generate surface points for a sphere approximation.
/// Returns list of (position, normal) pairs.
pub fn sphere_points(
  radius: Float,
  lat_steps: Int,
  lon_steps: Int,
) -> List(#(Vec3, Vec3)) {
  sphere_lat_loop(radius, lat_steps, lon_steps, 1, [])
}

fn sphere_lat_loop(
  r: Float,
  lat_steps: Int,
  lon_steps: Int,
  lat: Int,
  acc: List(#(Vec3, Vec3)),
) -> List(#(Vec3, Vec3)) {
  case lat >= lat_steps {
    True -> acc
    False -> {
      let theta =
        math3d.pi() *. int.to_float(lat) /. int.to_float(lat_steps)
      let new_acc = sphere_lon_loop(r, theta, lon_steps, 0, acc)
      sphere_lat_loop(r, lat_steps, lon_steps, lat + 1, new_acc)
    }
  }
}

fn sphere_lon_loop(
  r: Float,
  theta: Float,
  lon_steps: Int,
  lon: Int,
  acc: List(#(Vec3, Vec3)),
) -> List(#(Vec3, Vec3)) {
  case lon >= lon_steps {
    True -> acc
    False -> {
      let phi =
        2.0 *. math3d.pi() *. int.to_float(lon) /. int.to_float(lon_steps)
      let nx = math3d.sin(theta) *. math3d.cos(phi)
      let ny = math3d.cos(theta)
      let nz = math3d.sin(theta) *. math3d.sin(phi)
      let normal = Vec3(nx, ny, nz)
      let position = math3d.vec3_scale(normal, r)
      sphere_lon_loop(r, theta, lon_steps, lon + 1, [
        #(position, normal),
        ..acc
      ])
    }
  }
}

// ---------------------------------------------------------------------------
// Drag state
// ---------------------------------------------------------------------------

pub type DragState {
  Idle
  Dragging(start_x: Int, start_y: Int, start_rx: Float, start_ry: Float)
}

/// Compute new rotation from drag state and current mouse position.
pub fn drag_rotation(
  state: DragState,
  mouse_x: Int,
  mouse_y: Int,
) -> #(Float, Float) {
  case state {
    Idle -> #(0.0, 0.0)
    Dragging(start_x:, start_y:, start_rx:, start_ry:) -> {
      let dx = int.to_float(mouse_x - start_x) *. 0.02
      let dy = int.to_float(mouse_y - start_y) *. 0.02
      #(start_rx +. dy, start_ry +. dx)
    }
  }
}

// ---------------------------------------------------------------------------
// Showcase layout
// ---------------------------------------------------------------------------

pub type DemoPanel {
  DemoPanel(id: String, title: String, x: Int, y: Int, w: Int, h: Int)
}

pub fn showcase_panels() -> List(DemoPanel) {
  [
    DemoPanel("stats", "Live Stats", 2, 2, 25, 7),
    DemoPanel("fractal", "Fractal", 28, 2, 25, 7),
    DemoPanel("anim", "Animation", 54, 2, 24, 7),
    DemoPanel("unicode", "Unicode", 2, 10, 25, 7),
    DemoPanel("cube", "3D Cube", 28, 10, 25, 7),
    DemoPanel("arch", "Architecture", 54, 10, 24, 7),
  ]
}

pub fn panel_count() -> Int {
  6
}

// ---------------------------------------------------------------------------
// Line drawing (Bresenham-like for wireframe)
// ---------------------------------------------------------------------------

/// Generate character positions along a line from (x0,y0) to (x1,y1).
pub fn line_points(
  x0: Int,
  y0: Int,
  x1: Int,
  y1: Int,
) -> List(#(Int, Int)) {
  let dx = int.absolute_value(x1 - x0)
  let dy = int.absolute_value(y1 - y0)
  let sx = case x1 > x0 {
    True -> 1
    False -> -1
  }
  let sy = case y1 > y0 {
    True -> 1
    False -> -1
  }
  bresenham(x0, y0, x1, y1, dx, dy, sx, sy, dx - dy, [])
}

fn bresenham(
  x: Int,
  y: Int,
  x1: Int,
  y1: Int,
  dx: Int,
  dy: Int,
  sx: Int,
  sy: Int,
  err: Int,
  acc: List(#(Int, Int)),
) -> List(#(Int, Int)) {
  let new_acc = [#(x, y), ..acc]
  case x == x1 && y == y1 {
    True -> new_acc
    False -> {
      let e2 = 2 * err
      let #(new_x, new_err_x) = case e2 > 0 - dy {
        True -> #(x + sx, err - dy)
        False -> #(x, err)
      }
      let #(new_y, new_err_y) = case e2 < dx {
        True -> #(y + sy, new_err_x + dx)
        False -> #(y, new_err_x)
      }
      bresenham(new_x, new_y, x1, y1, dx, dy, sx, sy, new_err_y, new_acc)
    }
  }
}
