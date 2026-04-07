import opentui/interaction

pub type DragState {
  DragState(
    left: Int,
    top: Int,
    width: Int,
    height: Int,
    drag: interaction.DragSession,
    rot_x: Float,
    rot_y: Float,
    mesh_idx: Int,
    rotation_enabled: Bool,
  )
}

const header_height = 4

pub fn create(term_width: Int, term_height: Int) -> DragState {
  let #(width, height) = render_size(term_width, term_height)
  let left = max_int(2, term_width / 2 - width / 2)
  let top = max_int(header_height, term_height / 2 - height / 2)
  DragState(
    left,
    top,
    width,
    height,
    interaction.idle_drag(),
    0.4,
    0.6,
    0,
    True,
  )
}

pub fn render_size(term_width: Int, term_height: Int) -> #(Int, Int) {
  let width =
    interaction.clamp_region(
      interaction.region(term_width * 55 / 100, 0, 0, 0),
      interaction.bounds(24, 0, 64, 0),
    ).left
  let height =
    interaction.clamp_region(
      interaction.region(term_height * 55 / 100, 0, 0, 0),
      interaction.bounds(12, 0, 28, 0),
    ).left
  #(width, height)
}

pub fn begin_drag(state: DragState, pointer_x: Int, pointer_y: Int) -> DragState {
  DragState(
    ..state,
    drag: interaction.begin_drag(
      state.drag,
      interaction.region(state.left, state.top, state.width, state.height),
      pointer_x,
      pointer_y,
    ),
  )
}

pub fn drag_to(
  state: DragState,
  pointer_x: Int,
  pointer_y: Int,
  term_width: Int,
  term_height: Int,
) -> DragState {
  let max_left = max_int(0, term_width - state.width)
  let max_top = max_int(header_height, term_height - state.height)
  let next =
    interaction.drag_to(
      state.drag,
      interaction.bounds(0, header_height, max_left, max_top),
      pointer_x,
      pointer_y,
    )
  case state.drag.active {
    False -> state
    True -> DragState(..state, left: next.left, top: next.top)
  }
}

pub fn end_drag(state: DragState) -> DragState {
  DragState(..state, drag: interaction.end_drag(state.drag))
}

pub fn resize(state: DragState, term_width: Int, term_height: Int) -> DragState {
  let #(next_width, next_height) = render_size(term_width, term_height)
  let max_left = max_int(0, term_width - next_width)
  let max_top = max_int(header_height, term_height - next_height)
  let clamped =
    interaction.clamp_region(
      interaction.region(state.left, state.top, next_width, next_height),
      interaction.bounds(0, header_height, max_left, max_top),
    )
  DragState(
    ..state,
    width: next_width,
    height: next_height,
    left: clamped.left,
    top: clamped.top,
  )
}

pub fn step_rotation(state: DragState, dt_ms: Float) -> DragState {
  case state.rotation_enabled {
    False -> state
    True ->
      DragState(
        ..state,
        rot_x: state.rot_x +. 0.0006 *. dt_ms,
        rot_y: state.rot_y +. 0.0004 *. dt_ms,
      )
  }
}

pub fn nudge_rotation(state: DragState, dx: Float, dy: Float) -> DragState {
  DragState(..state, rot_x: state.rot_x +. dy, rot_y: state.rot_y +. dx)
}

pub fn toggle_rotation(state: DragState) -> DragState {
  DragState(..state, rotation_enabled: !state.rotation_enabled)
}

pub fn next_mesh(state: DragState) -> DragState {
  DragState(..state, mesh_idx: { state.mesh_idx + 1 } % 2)
}

pub fn mesh_name(state: DragState) -> String {
  case state.mesh_idx {
    0 -> "Cube"
    _ -> "Pyramid"
  }
}

pub fn is_rotation_enabled(state: DragState) -> Bool {
  state.rotation_enabled
}

pub fn hit_test(state: DragState, x: Int, y: Int) -> Bool {
  interaction.hit_test(
    interaction.region(state.left, state.top, state.width, state.height),
    x,
    y,
  )
}

fn max_int(a: Int, b: Int) -> Int {
  case a > b {
    True -> a
    False -> b
  }
}

pub fn status_text(state: DragState) -> String {
  let rotation_text = case state.rotation_enabled {
    True -> "auto"
    False -> "paused"
  }
  let drag_text = case state.drag.active {
    True -> "dragging"
    False -> "idle"
  }
  "mouse drag: move viewport  |  space: "
  <> rotation_text
  <> "  |  tab: mesh  |  "
  <> drag_text
}

pub fn instructions_text() -> String {
  "Drag inside the 3D panel with the mouse. Arrows fine-tune rotation; Tab switches mesh."
}
