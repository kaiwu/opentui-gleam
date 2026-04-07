import gleeunit/should
import opentui/examples/physx_planck_2d_demo_model as model

pub fn create_starts_with_seeded_bodies_test() {
  let system = model.create()
  model.body_count(system) |> should.equal(3)
}

pub fn spawn_increments_body_count_test() {
  let system = model.create()
  let system = model.spawn(system)
  model.body_count(system) |> should.equal(4)
}

pub fn burst_adds_multiple_bodies_test() {
  let system = model.create()
  let system = model.burst(system)
  model.body_count(system) |> should.equal(7)
}

pub fn toggle_auto_flips_state_test() {
  let system = model.create()
  let system = model.toggle_auto(system)
  model.is_auto(system) |> should.equal(False)
}

pub fn toggle_pause_flips_state_test() {
  let system = model.create()
  let system = model.toggle_pause(system)
  model.is_paused(system) |> should.equal(True)
}

pub fn clear_removes_all_bodies_test() {
  let system = model.clear(model.create())
  model.body_count(system) |> should.equal(0)
}

pub fn reset_restores_initial_state_test() {
  let system =
    model.create()
    |> model.clear
    |> model.toggle_auto
    |> model.toggle_pause
  let system = model.reset(system)
  let _ = model.body_count(system) |> should.equal(3)
  let _ = model.is_auto(system) |> should.equal(True)
  model.is_paused(system) |> should.equal(False)
}

pub fn auto_spawn_adds_body_after_interval_test() {
  let system = model.create()
  let system = model.tick(system, 900.0)
  model.body_count(system) |> should.equal(4)
}

pub fn paused_tick_does_not_auto_spawn_test() {
  let system = model.create() |> model.toggle_pause
  let system = model.tick(system, 1600.0)
  model.body_count(system) |> should.equal(3)
}

pub fn clear_preserves_auto_state_test() {
  let system = model.create()
  let system = model.clear(system)
  let _ = model.body_count(system) |> should.equal(0)
  model.is_auto(system) |> should.equal(True)
}

pub fn status_mentions_body_count_and_auto_test() {
  let status = model.format_status(model.create())
  status |> should.equal("bodies: 3/24  auto: on  running")
}

pub fn instructions_text_test() {
  model.format_instructions()
  |> should.equal(
    "Space: spawn  b: burst  a: auto  c: clear  r: reset  p: pause",
  )
}
