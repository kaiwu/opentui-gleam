import gleam/float
import gleam/int
import gleam/list
import opentui/buffer
import opentui/examples/common
import opentui/examples/draggable_three_demo_model as model_state
import opentui/examples/phase4_state as state
import opentui/examples/phase5_model as model
import opentui/ffi
import opentui/input
import opentui/lighting
import opentui/math3d.{type Vec3, Vec3}
import opentui/renderer

pub fn main() -> Nil {
  let drag_state =
    state.create_generic(model_state.create(common.term_w, common.term_h))

  common.run_event_demo_with_setup(
    "Draggable Three Demo",
    "Draggable Three Demo",
    fn(r) { renderer.enable_mouse(r, True) },
    fn(r, event) { handle_event(r, drag_state, event) },
    fn(_r, buf) { draw(buf, drag_state) },
  )
}

fn handle_event(
  renderer: ffi.Renderer,
  drag_state: state.GenericCell,
  event: input.Event,
) -> Nil {
  case event {
    input.KeyEvent(raw, key) -> handle_key(drag_state, raw, key)
    input.MouseEvent(mouse) -> handle_mouse(renderer, drag_state, mouse)
    input.UnknownEvent(_) -> Nil
  }
}

fn handle_key(drag_state: state.GenericCell, raw: String, key: input.Key) -> Nil {
  let current = state.get_generic(drag_state)
  let updated = case key, raw {
    input.ArrowLeft, _ -> model_state.nudge_rotation(current, -0.16, 0.0)
    input.ArrowRight, _ -> model_state.nudge_rotation(current, 0.16, 0.0)
    input.ArrowUp, _ -> model_state.nudge_rotation(current, 0.0, -0.16)
    input.ArrowDown, _ -> model_state.nudge_rotation(current, 0.0, 0.16)
    input.Tab, _ -> model_state.next_mesh(current)
    input.Character(" "), _ -> model_state.toggle_rotation(current)
    _, _ -> current
  }
  state.set_generic(drag_state, updated)
}

fn handle_mouse(
  _renderer: ffi.Renderer,
  drag_state: state.GenericCell,
  mouse: input.MouseData,
) -> Nil {
  let current = state.get_generic(drag_state)
  let updated = case mouse.action, mouse.button {
    input.MousePress, input.LeftButton ->
      model_state.begin_drag(current, mouse.x, mouse.y)
    input.MouseDrag, input.LeftButton | input.MouseDrag, input.NoButton ->
      model_state.drag_to(
        current,
        mouse.x,
        mouse.y,
        common.term_w,
        common.term_h,
      )
    input.MouseRelease, _ -> model_state.end_drag(current)
    _, _ -> current
  }
  state.set_generic(drag_state, updated)
}

fn draw(buf: ffi.Buffer, drag_state: state.GenericCell) -> Nil {
  let viewport =
    state.get_generic(drag_state)
    |> model_state.step_rotation(16.0)
    |> model_state.resize(common.term_w, common.term_h)
  state.set_generic(drag_state, viewport)

  let mesh = case viewport.mesh_idx {
    0 -> model.cube_mesh()
    _ -> model.pyramid_mesh()
  }

  common.draw_panel(
    buf,
    2,
    2,
    76,
    19,
    "Draggable 3D — " <> model_state.mesh_name(viewport),
  )
  draw_viewport(buf, viewport)

  let light_dir = math3d.vec3_normalize(Vec3(0.5, 0.8, 0.6))
  let projected =
    list.map(mesh.vertices, fn(v) {
      let rotated = math3d.rotate_euler(v, viewport.rot_x, viewport.rot_y, 0.0)
      let #(sx, sy) =
        math3d.project_simple(
          rotated,
          12.0,
          int.to_float(viewport.left + viewport.width / 2),
          int.to_float(viewport.top + viewport.height / 2),
        )
      #(float.truncate(sx), float.truncate(sy), rotated)
    })

  draw_edges(buf, projected, mesh.edges, light_dir, viewport)
  draw_vertices(buf, projected, viewport)

  buffer.draw_text(
    buf,
    model_state.status_text(viewport),
    4,
    common.term_h - 1,
    common.fg_color,
    common.status_bg,
    0,
  )
  buffer.draw_text(
    buf,
    model_state.instructions_text(),
    4,
    19,
    common.muted_fg,
    common.panel_bg,
    0,
  )
}

fn draw_viewport(buf: ffi.Buffer, viewport: model_state.DragState) -> Nil {
  let bg = case viewport.dragging {
    True -> #(0.08, 0.11, 0.18, 1.0)
    False -> #(0.03, 0.05, 0.08, 1.0)
  }
  buffer.fill_rect(
    buf,
    viewport.left,
    viewport.top,
    viewport.width,
    viewport.height,
    bg,
  )
  draw_rect_outline(
    buf,
    viewport.left,
    viewport.top,
    viewport.width,
    viewport.height,
    case viewport.dragging {
      True -> common.accent_blue
      False -> common.border_fg
    },
  )
  buffer.draw_text(
    buf,
    "drag me",
    viewport.left + 2,
    viewport.top,
    common.fg_color,
    bg,
    0,
  )
}

fn draw_edges(
  buf: ffi.Buffer,
  projected: List(#(Int, Int, Vec3)),
  edges: List(model.Edge),
  light_dir: Vec3,
  state: model_state.DragState,
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
      draw_point_list(buf, points, char, color, state)
      draw_edges(buf, projected, rest, light_dir, state)
    }
  }
}

fn draw_vertices(
  buf: ffi.Buffer,
  projected: List(#(Int, Int, Vec3)),
  state: model_state.DragState,
) -> Nil {
  case projected {
    [] -> Nil
    [#(x, y, _), ..rest] -> {
      case in_viewport(state, x, y) {
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
      draw_vertices(buf, rest, state)
    }
  }
}

fn draw_point_list(
  buf: ffi.Buffer,
  points: List(#(Int, Int)),
  char: Int,
  color: #(Float, Float, Float, Float),
  state: model_state.DragState,
) -> Nil {
  case points {
    [] -> Nil
    [#(x, y), ..rest] -> {
      case in_viewport(state, x, y) {
        True ->
          buffer.set_cell(buf, x, y, char, color, #(0.0, 0.0, 0.0, 0.0), 0)
        False -> Nil
      }
      draw_point_list(buf, rest, char, color, state)
    }
  }
}

fn draw_rect_outline(
  buf: ffi.Buffer,
  x: Int,
  y: Int,
  w: Int,
  h: Int,
  color: #(Float, Float, Float, Float),
) -> Nil {
  common.each_index(w, fn(i) {
    buffer.set_cell(buf, x + i, y, 0x2500, color, #(0.0, 0.0, 0.0, 0.0), 0)
    buffer.set_cell(
      buf,
      x + i,
      y + h - 1,
      0x2500,
      color,
      #(0.0, 0.0, 0.0, 0.0),
      0,
    )
  })
  common.each_index(h, fn(i) {
    buffer.set_cell(buf, x, y + i, 0x2502, color, #(0.0, 0.0, 0.0, 0.0), 0)
    buffer.set_cell(
      buf,
      x + w - 1,
      y + i,
      0x2502,
      color,
      #(0.0, 0.0, 0.0, 0.0),
      0,
    )
  })
}

fn in_viewport(viewport: model_state.DragState, x: Int, y: Int) -> Bool {
  x > viewport.left
  && x < viewport.left + viewport.width - 1
  && y > viewport.top
  && y < viewport.top + viewport.height - 1
}

fn list_at(items: List(a), index: Int) -> a {
  case items, index {
    [item, ..], 0 -> item
    [_, ..rest], n -> list_at(rest, n - 1)
    [], _ -> panic as "list_at: index out of bounds"
  }
}
