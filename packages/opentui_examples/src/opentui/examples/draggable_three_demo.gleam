import gleam/float
import gleam/int
import gleam/list
import opentui/buffer
import opentui/examples/common
import opentui/examples/phase2_state as int_state
import opentui/examples/phase4_state as state
import opentui/examples/phase5_model as model
import opentui/ffi
import opentui/input
import opentui/lighting
import opentui/math3d.{Vec3}
import opentui/renderer

pub fn main() -> Nil {
  let rot_x = state.create_float(0.4)
  let rot_y = state.create_float(0.6)
  let mesh_idx = int_state.create_int(0)

  common.run_interactive_demo_with_setup(
    "Draggable Three Demo",
    "Draggable Three Demo",
    fn(r) { renderer.enable_mouse(r, True) },
    fn(raw) { handle_key(rot_x, rot_y, mesh_idx, raw) },
    fn(buf) { draw(buf, rot_x, rot_y, mesh_idx) },
  )
}

fn handle_key(
  rot_x: state.FloatCell,
  rot_y: state.FloatCell,
  mesh_idx: int_state.IntCell,
  raw: String,
) -> Nil {
  case input.parse_key(raw) {
    input.ArrowLeft ->
      state.set_float(rot_y, state.get_float(rot_y) -. 0.2)
    input.ArrowRight ->
      state.set_float(rot_y, state.get_float(rot_y) +. 0.2)
    input.ArrowUp ->
      state.set_float(rot_x, state.get_float(rot_x) -. 0.2)
    input.ArrowDown ->
      state.set_float(rot_x, state.get_float(rot_x) +. 0.2)
    input.Tab ->
      int_state.set_int(mesh_idx, { int_state.get_int(mesh_idx) + 1 } % 2)
    _ -> Nil
  }
}

fn draw(
  buf: ffi.Buffer,
  rot_x: state.FloatCell,
  rot_y: state.FloatCell,
  mesh_idx: int_state.IntCell,
) -> Nil {
  let rx = state.get_float(rot_x)
  let ry = state.get_float(rot_y)
  let idx = int_state.get_int(mesh_idx)

  let mesh = case idx {
    0 -> model.cube_mesh()
    _ -> model.pyramid_mesh()
  }
  let mesh_name = case idx {
    0 -> "Cube"
    _ -> "Pyramid"
  }

  common.draw_panel(buf, 2, 2, 76, 19, "Draggable 3D — " <> mesh_name)

  let light_dir = math3d.vec3_normalize(Vec3(0.5, 0.8, 0.6))

  // Transform and project
  let projected =
    list.map(mesh.vertices, fn(v) {
      let rotated = math3d.rotate_euler(v, rx, ry, 0.0)
      let #(sx, sy) = math3d.project_simple(rotated, 14.0, 40.0, 11.0)
      #(float.truncate(sx), float.truncate(sy), rotated)
    })

  // Draw edges
  draw_edges(buf, mesh.edges, projected, light_dir)

  // Draw vertices
  draw_vertices(buf, projected)

  buffer.draw_text(
    buf,
    "Arrow keys rotate  |  Tab: switch mesh  |  rx="
      <> float_1(rx)
      <> " ry="
      <> float_1(ry),
    4,
    common.term_h - 1,
    common.fg_color,
    common.status_bg,
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
      let #(ax, ay, a_pos) = list_at(projected, edge.a)
      let #(bx, by, b_pos) = list_at(projected, edge.b)

      let mid = math3d.vec3_scale(math3d.vec3_add(a_pos, b_pos), 0.5)
      let normal = math3d.vec3_normalize(mid)
      let brightness = lighting.diffuse(normal, light_dir) *. 0.6 +. 0.4

      let points = model.line_points(ax, ay, bx, by)
      let char = model.shade_char(brightness)
      let color = #(brightness *. 0.4, brightness *. 0.7, brightness, 1.0)
      draw_point_list(buf, points, char, color)

      draw_edges(buf, rest, projected, light_dir)
    }
  }
}

fn draw_vertices(buf: ffi.Buffer, projected: List(#(Int, Int, Vec3))) -> Nil {
  case projected {
    [] -> Nil
    [#(x, y, _), ..rest] -> {
      case x >= 3 && x < 77 && y >= 3 && y < 20 {
        True ->
          buffer.set_cell(
            buf,
            x,
            y,
            0x25CF,
            common.accent_orange,
            #(0.0, 0.0, 0.0, 0.0),
            0,
          )
        False -> Nil
      }
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

fn float_1(f: Float) -> String {
  let whole = float.truncate(f)
  let frac =
    float.truncate({ f -. int.to_float(whole) } *. 10.0)
  int.to_string(whole) <> "." <> int.to_string(int.absolute_value(frac))
}
