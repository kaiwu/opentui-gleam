import gleeunit/should
import opentui/examples/draggable_three_demo_model as model

pub fn create_centers_panel_test() {
  let state = model.create(80, 24)
  let _ = state.left |> should.equal(18)
  state.top |> should.equal(6)
}

pub fn begin_drag_sets_dragging_inside_panel_test() {
  let state = model.create(80, 24)
  let state = model.begin_drag(state, state.left + 1, state.top + 1)
  state.dragging |> should.equal(True)
}

pub fn drag_to_clamps_to_bounds_test() {
  let state = model.create(80, 24)
  let state = model.begin_drag(state, state.left + 2, state.top + 2)
  let state = model.drag_to(state, 999, 999, 80, 24)
  let _ = state.left |> should.equal(36)
  state.top |> should.equal(11)
}

pub fn end_drag_clears_dragging_test() {
  let state = model.create(80, 24)
  let state = model.begin_drag(state, state.left + 1, state.top + 1)
  let state = model.end_drag(state)
  state.dragging |> should.equal(False)
}

pub fn step_rotation_changes_angles_when_enabled_test() {
  let state = model.create(80, 24)
  let state = model.step_rotation(state, 1000.0)
  let _ = state.rot_x |> should.equal(1.0)
  state.rot_y |> should.equal(1.0)
}

pub fn toggle_rotation_stops_step_test() {
  let state = model.create(80, 24) |> model.toggle_rotation
  let state = model.step_rotation(state, 1000.0)
  let _ = state.rot_x |> should.equal(0.4)
  state.rot_y |> should.equal(0.6)
}

pub fn next_mesh_changes_name_test() {
  let state = model.create(80, 24) |> model.next_mesh
  model.mesh_name(state) |> should.equal("Pyramid")
}

pub fn status_mentions_mouse_drag_test() {
  model.status_text(model.create(80, 24))
  |> should.equal(
    "mouse drag: move viewport  |  space: auto  |  tab: mesh  |  idle",
  )
}
