pub type DragState {
  DragState(
    left: Int,
    top: Int,
    width: Int,
    height: Int,
    dragging: Bool,
    drag_offset_x: Int,
    drag_offset_y: Int,
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
  DragState(left, top, width, height, False, 0, 0, 0.4, 0.6, 0, True)
}

pub fn render_size(term_width: Int, term_height: Int) -> #(Int, Int) {
  #(
    clamp_int(term_width * 55 / 100, 24, 64),
    clamp_int(term_height * 55 / 100, 12, 28),
  )
}

pub fn begin_drag(state: DragState, pointer_x: Int, pointer_y: Int) -> DragState {
  case hit_test(state, pointer_x, pointer_y) {
    True ->
      DragState(
        ..state,
        dragging: True,
        drag_offset_x: pointer_x - state.left,
        drag_offset_y: pointer_y - state.top,
      )
    False -> state
  }
}

pub fn drag_to(
  state: DragState,
  pointer_x: Int,
  pointer_y: Int,
  term_width: Int,
  term_height: Int,
) -> DragState {
  case state.dragging {
    False -> state
    True -> {
      let max_left = max_int(0, term_width - state.width)
      let max_top = max_int(header_height, term_height - state.height)
      let next_left = clamp_int(pointer_x - state.drag_offset_x, 0, max_left)
      let next_top =
        clamp_int(pointer_y - state.drag_offset_y, header_height, max_top)
      DragState(..state, left: next_left, top: next_top)
    }
  }
}

pub fn end_drag(state: DragState) -> DragState {
  DragState(..state, dragging: False)
}

pub fn resize(state: DragState, term_width: Int, term_height: Int) -> DragState {
  let #(next_width, next_height) = render_size(term_width, term_height)
  let max_left = max_int(0, term_width - next_width)
  let max_top = max_int(header_height, term_height - next_height)
  DragState(
    ..state,
    width: next_width,
    height: next_height,
    left: clamp_int(state.left, 0, max_left),
    top: clamp_int(state.top, header_height, max_top),
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
  x >= state.left
  && x < state.left + state.width
  && y >= state.top
  && y < state.top + state.height
}

fn clamp_int(value: Int, low: Int, high: Int) -> Int {
  case value < low {
    True -> low
    False ->
      case value > high {
        True -> high
        False -> value
      }
  }
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
  let drag_text = case state.dragging {
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
