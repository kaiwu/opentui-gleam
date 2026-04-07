import gleam/float
import gleam/int
import gleam/list
import opentui/draw_plan
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

  draw_plan.render(
    buf,
    plan_for_view(viewport, projected, mesh.edges, light_dir),
  )
}

fn plan_for_view(
  viewport: model_state.DragState,
  projected: List(#(Int, Int, Vec3)),
  edges: List(model.Edge),
  light_dir: Vec3,
) -> List(draw_plan.DrawOp) {
  draw_plan.concat([
    viewport_plan(viewport),
    edge_plan(projected, edges, light_dir, viewport),
    vertex_plan(projected, viewport),
    [
      draw_plan.text(
        4,
        common.term_h - 1,
        model_state.status_text(viewport),
        color(common.fg_color),
        color(common.status_bg),
        0,
      ),
      draw_plan.text(
        4,
        19,
        model_state.instructions_text(),
        color(common.muted_fg),
        color(common.panel_bg),
        0,
      ),
    ],
  ])
}

fn viewport_plan(viewport: model_state.DragState) -> List(draw_plan.DrawOp) {
  let bg = case viewport.drag.active {
    True -> draw_plan.Color(0.08, 0.11, 0.18, 1.0)
    False -> draw_plan.Color(0.03, 0.05, 0.08, 1.0)
  }
  draw_plan.concat([
    [
      draw_plan.fill_rect(
        viewport.left,
        viewport.top,
        viewport.width,
        viewport.height,
        bg,
      ),
    ],
    rect_outline_plan(
      viewport.left,
      viewport.top,
      viewport.width,
      viewport.height,
      case viewport.drag.active {
        True -> color(common.accent_blue)
        False -> color(common.border_fg)
      },
    ),
    [
      draw_plan.text(
        viewport.left + 2,
        viewport.top,
        "drag me",
        color(common.fg_color),
        bg,
        0,
      ),
    ],
  ])
}

fn edge_plan(
  projected: List(#(Int, Int, Vec3)),
  edges: List(model.Edge),
  light_dir: Vec3,
  viewport: model_state.DragState,
) -> List(draw_plan.DrawOp) {
  case edges {
    [] -> []
    [edge, ..rest] -> {
      let #(ax, ay, a_pos) = list_at(projected, edge.a)
      let #(bx, by, b_pos) = list_at(projected, edge.b)
      let mid = math3d.vec3_scale(math3d.vec3_add(a_pos, b_pos), 0.5)
      let normal = math3d.vec3_normalize(mid)
      let brightness = lighting.diffuse(normal, light_dir) *. 0.6 +. 0.4
      let points = model.line_points(ax, ay, bx, by)
      let char = model.shade_char(brightness)
      let edge_color =
        draw_plan.Color(brightness *. 0.4, brightness *. 0.7, brightness, 1.0)
      draw_plan.concat([
        point_plan(points, char, edge_color, viewport),
        edge_plan(projected, rest, light_dir, viewport),
      ])
    }
  }
}

fn vertex_plan(
  projected: List(#(Int, Int, Vec3)),
  viewport: model_state.DragState,
) -> List(draw_plan.DrawOp) {
  case projected {
    [] -> []
    [#(x, y, _), ..rest] -> {
      let head = case in_viewport(viewport, x, y) {
        True -> [
          draw_plan.cell(
            x,
            y,
            0x25CF,
            color(common.accent_orange),
            transparent(),
            0,
          ),
        ]
        False -> []
      }
      draw_plan.concat([head, vertex_plan(rest, viewport)])
    }
  }
}

fn point_plan(
  points: List(#(Int, Int)),
  char: Int,
  fg: draw_plan.Color,
  viewport: model_state.DragState,
) -> List(draw_plan.DrawOp) {
  case points {
    [] -> []
    [#(x, y), ..rest] -> {
      let head = case in_viewport(viewport, x, y) {
        True -> [draw_plan.cell(x, y, char, fg, transparent(), 0)]
        False -> []
      }
      draw_plan.concat([head, point_plan(rest, char, fg, viewport)])
    }
  }
}

fn rect_outline_plan(
  x: Int,
  y: Int,
  w: Int,
  h: Int,
  fg: draw_plan.Color,
) -> List(draw_plan.DrawOp) {
  draw_plan.concat([
    horizontal_border_plan(x, y, w, fg),
    horizontal_border_plan(x, y + h - 1, w, fg),
    vertical_border_plan(x, y, h, fg),
    vertical_border_plan(x + w - 1, y, h, fg),
  ])
}

fn horizontal_border_plan(
  x: Int,
  y: Int,
  w: Int,
  fg: draw_plan.Color,
) -> List(draw_plan.DrawOp) {
  horizontal_border_plan_loop(x, y, w, fg, 0)
}

fn horizontal_border_plan_loop(
  x: Int,
  y: Int,
  w: Int,
  fg: draw_plan.Color,
  i: Int,
) -> List(draw_plan.DrawOp) {
  case i >= w {
    True -> []
    False -> [
      draw_plan.cell(x + i, y, 0x2500, fg, transparent(), 0),
      ..horizontal_border_plan_loop(x, y, w, fg, i + 1)
    ]
  }
}

fn vertical_border_plan(
  x: Int,
  y: Int,
  h: Int,
  fg: draw_plan.Color,
) -> List(draw_plan.DrawOp) {
  vertical_border_plan_loop(x, y, h, fg, 0)
}

fn vertical_border_plan_loop(
  x: Int,
  y: Int,
  h: Int,
  fg: draw_plan.Color,
  i: Int,
) -> List(draw_plan.DrawOp) {
  case i >= h {
    True -> []
    False -> [
      draw_plan.cell(x, y + i, 0x2502, fg, transparent(), 0),
      ..vertical_border_plan_loop(x, y, h, fg, i + 1)
    ]
  }
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

fn color(tuple: #(Float, Float, Float, Float)) -> draw_plan.Color {
  draw_plan.Color(tuple.0, tuple.1, tuple.2, tuple.3)
}

fn transparent() -> draw_plan.Color {
  draw_plan.Color(0.0, 0.0, 0.0, 0.0)
}
