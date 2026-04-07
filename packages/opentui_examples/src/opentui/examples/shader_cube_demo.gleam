import gleam/float
import gleam/list
import opentui/buffer
import opentui/examples/common
import opentui/examples/phase4_state as state
import opentui/examples/phase5_model as model
import opentui/ffi
import opentui/lighting
import opentui/math3d.{Vec3}

pub fn main() -> Nil {
  let angle_y = state.create_float(0.0)
  let angle_x = state.create_float(0.3)

  common.run_animated_demo(
    "Shader Cube Demo",
    "Shader Cube Demo",
    fn(_key) { Nil },
    fn(dt) {
      state.set_float(angle_y, state.get_float(angle_y) +. dt *. 0.001)
      state.set_float(
        angle_x,
        0.3 +. math3d.sin(state.get_float(angle_y) *. 0.5) *. 0.2,
      )
    },
    fn(buf) { draw(buf, angle_x, angle_y) },
  )
}

fn draw(buf: ffi.Buffer, angle_x: state.FloatCell, angle_y: state.FloatCell) -> Nil {
  let rx = state.get_float(angle_x)
  let ry = state.get_float(angle_y)
  let mesh = model.cube_mesh()

  common.draw_panel(buf, 2, 2, 76, 19, "Wireframe Cube — Pure 3D Projection")

  // Light direction for shading edges
  let light_dir = math3d.vec3_normalize(Vec3(0.5, 0.8, 0.6))

  // Transform and project vertices
  let projected =
    list.map(mesh.vertices, fn(v) {
      let rotated = math3d.rotate_euler(v, rx, ry, 0.0)
      let #(sx, sy, _depth) =
        math3d.project_simple(rotated, 12.0, 40.0, 11.0)
      #(float.truncate(sx), float.truncate(sy), rotated)
    })

  // Draw edges
  draw_edges(buf, mesh.edges, projected, light_dir)

  // Draw vertices as bright dots
  draw_vertices(buf, projected)

  buffer.draw_text(
    buf,
    "Pure Gleam: rotate -> project -> shade -> draw",
    6,
    19,
    common.muted_fg,
    common.panel_bg,
    0,
  )
}

fn draw_edges(
  buf: ffi.Buffer,
  edges: List(model.Edge),
  projected: List(#(Int, Int, Vec3)),
  light_dir: Vec3,
) -> Nil {
  case edges {
    [] -> Nil
    [edge, ..rest] -> {
      let a = list_at(projected, edge.a)
      let b = list_at(projected, edge.b)
      let #(ax, ay, a_pos) = a
      let #(bx, by, b_pos) = b

      // Edge direction as approximate normal for shading
      let mid = math3d.vec3_scale(math3d.vec3_add(a_pos, b_pos), 0.5)
      let normal = math3d.vec3_normalize(mid)
      let brightness =
        lighting.diffuse(normal, light_dir) *. 0.7 +. 0.3

      let points = model.line_points(ax, ay, bx, by)
      let char = model.shade_char(brightness)
      let color = #(brightness *. 0.6, brightness *. 0.8, brightness, 1.0)
      draw_point_list(buf, points, char, color)

      draw_edges(buf, rest, projected, light_dir)
    }
  }
}

fn draw_vertices(
  buf: ffi.Buffer,
  projected: List(#(Int, Int, Vec3)),
) -> Nil {
  case projected {
    [] -> Nil
    [#(x, y, _), ..rest] -> {
      buffer.set_cell(
        buf,
        x,
        y,
        0x25CF,
        common.accent_green,
        #(0.0, 0.0, 0.0, 0.0),
        0,
      )
      draw_vertices(buf, rest)
    }
  }
}

fn draw_point_list(
  buf: ffi.Buffer,
  points: List(#(Int, Int)),
  char: Int,
  color: #(Float, Float, Float, Float),
) -> Nil {
  case points {
    [] -> Nil
    [#(x, y), ..rest] -> {
      case x >= 3 && x < 77 && y >= 3 && y < 20 {
        True ->
          buffer.set_cell(buf, x, y, char, color, #(0.0, 0.0, 0.0, 0.0), 0)
        False -> Nil
      }
      draw_point_list(buf, rest, char, color)
    }
  }
}

fn list_at(items: List(a), index: Int) -> a {
  case items, index {
    [item, ..], 0 -> item
    [_, ..rest], n -> list_at(rest, n - 1)
    [], _ -> panic as "list_at: index out of bounds"
  }
}
