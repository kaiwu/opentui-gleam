import gleam/int
import gleam/list
import opentui/draw_plan
import opentui/examples/common
import opentui/examples/draggable_three_demo_model as model_state
import opentui/examples/phase4_state as state
import opentui/examples/phase5_model as model
import opentui/ffi
import opentui/input
import opentui/interaction
import opentui/math3d.{type Vec3, Vec3}
import opentui/renderer
import opentui/wireframe

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
  let wireframe_mesh = to_wireframe_mesh(mesh)
  let projected =
    wireframe.project_mesh(
      wireframe_mesh,
      viewport.rot_x,
      viewport.rot_y,
      0.0,
      12.0,
      int.to_float(viewport.left + viewport.width / 2),
      int.to_float(viewport.top + viewport.height / 2),
    )

  draw_plan.render(
    buf,
    plan_for_view(viewport, wireframe_mesh, projected, light_dir),
  )
}

fn plan_for_view(
  viewport: model_state.DragState,
  mesh: wireframe.Mesh3d,
  projected: List(wireframe.ProjectedVertex),
  light_dir: Vec3,
) -> List(draw_plan.DrawOp) {
  draw_plan.concat([
    viewport_plan(viewport),
    wireframe_plan(viewport, mesh, projected, light_dir),
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

fn wireframe_plan(
  viewport: model_state.DragState,
  mesh: wireframe.Mesh3d,
  projected: List(wireframe.ProjectedVertex),
  light_dir: Vec3,
) -> List(draw_plan.DrawOp) {
  wireframe.rasterize(
    mesh,
    projected,
    light_dir,
    wireframe.viewport(
      viewport.left,
      viewport.top,
      viewport.width,
      viewport.height,
    ),
  )
  |> list.map(raster_cell_to_draw_op)
}

fn viewport_plan(viewport: model_state.DragState) -> List(draw_plan.DrawOp) {
  let bg = case viewport.drag {
    interaction.DragSession(True, _, _) ->
      draw_plan.Color(0.08, 0.11, 0.18, 1.0)
    interaction.DragSession(False, _, _) ->
      draw_plan.Color(0.03, 0.05, 0.08, 1.0)
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
      case viewport.drag {
        interaction.DragSession(True, _, _) -> color(common.accent_blue)
        interaction.DragSession(False, _, _) -> color(common.border_fg)
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

fn raster_cell_to_draw_op(cell: wireframe.RasterCell) -> draw_plan.DrawOp {
  case cell {
    wireframe.RasterCell(x, y, codepoint, _, True) ->
      draw_plan.cell(
        x,
        y,
        codepoint,
        color(common.accent_orange),
        transparent(),
        0,
      )
    wireframe.RasterCell(x, y, codepoint, brightness, False) ->
      draw_plan.cell(
        x,
        y,
        codepoint,
        draw_plan.Color(brightness *. 0.4, brightness *. 0.7, brightness, 1.0),
        transparent(),
        0,
      )
  }
}

fn to_wireframe_mesh(mesh: model.Mesh3D) -> wireframe.Mesh3d {
  wireframe.mesh(
    mesh.vertices,
    mesh.edges
      |> list.map(fn(edge) { wireframe.edge(edge.a, edge.b) }),
  )
}

fn color(tuple: #(Float, Float, Float, Float)) -> draw_plan.Color {
  draw_plan.Color(tuple.0, tuple.1, tuple.2, tuple.3)
}

fn transparent() -> draw_plan.Color {
  draw_plan.Color(0.0, 0.0, 0.0, 0.0)
}
