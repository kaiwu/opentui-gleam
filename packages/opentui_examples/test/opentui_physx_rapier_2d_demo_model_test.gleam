import gleeunit/should
import opentui/examples/physx_rapier_2d_demo_model as model

pub fn create_starts_with_more_seeded_bodies_test() {
  model.create() |> model.body_count |> should.equal(6)
}

pub fn burst_adds_six_bodies_test() {
  model.create() |> model.burst |> model.body_count |> should.equal(12)
}

pub fn auto_spawn_adds_after_interval_test() {
  model.create()
  |> fn(system) { model.tick(system, 900.0) }
  |> model.body_count
  |> should.equal(7)
}

pub fn clear_removes_all_bodies_test() {
  model.create() |> model.clear |> model.body_count |> should.equal(0)
}

pub fn reset_restores_default_state_test() {
  let system =
    model.create() |> model.clear |> model.toggle_auto |> model.toggle_pause
  let system = model.reset(system)
  let _ = model.body_count(system) |> should.equal(6)
  let _ = model.is_auto(system) |> should.equal(True)
  model.is_paused(system) |> should.equal(False)
}

pub fn status_text_matches_demo_identity_test() {
  model.format_status(model.create())
  |> should.equal("crates: 6/28  auto: on  running  bounce: high")
}

pub fn instructions_text_test() {
  model.format_instructions()
  |> should.equal(
    "Space: crate  b: burst  a: auto  c: clear  r: reset  p: pause",
  )
}
