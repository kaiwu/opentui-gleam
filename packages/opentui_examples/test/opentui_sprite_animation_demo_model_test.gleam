import gleam/float
import gleeunit/should
import opentui/examples/sprite_animation_demo_model as model

// --- Creation ---

pub fn create_default_test() {
  let anim = model.create(4)
  let _ = anim.running |> should.equal(True)
  let _ = anim.elapsed_ms |> should.equal(0.0)
  let _ = anim.frame_duration_ms |> should.equal(200.0)
  anim.frame_count |> should.equal(4)
}

pub fn create_with_duration_test() {
  let anim = model.create_with_duration(4, 100.0)
  anim.frame_duration_ms |> should.equal(100.0)
}

pub fn create_with_duration_clamped_low_test() {
  let anim = model.create_with_duration(4, 10.0)
  // below 50ms minimum
  anim.frame_duration_ms |> should.equal(50.0)
}

pub fn create_with_duration_clamped_high_test() {
  let anim = model.create_with_duration(4, 5000.0)
  // above 2000ms maximum
  anim.frame_duration_ms |> should.equal(2000.0)
}

// --- Tick ---

pub fn tick_advances_when_running_test() {
  let anim = model.tick(model.create(4), 150.0)
  anim.elapsed_ms |> should.equal(150.0)
}

pub fn tick_does_not_advance_when_paused_test() {
  let anim = model.pause(model.create(4))
  let anim = model.tick(anim, 150.0)
  anim.elapsed_ms |> should.equal(0.0)
}

// --- Pause/Resume ---

pub fn pause_stops_animation_test() {
  let anim = model.pause(model.create(4))
  anim.running |> should.equal(False)
}

pub fn resume_starts_animation_test() {
  let anim = model.resume(model.pause(model.create(4)))
  anim.running |> should.equal(True)
}

pub fn toggle_running_flips_state_test() {
  let anim = model.toggle_running(model.create(4))
  anim.running |> should.equal(False)
  let anim = model.toggle_running(anim)
  anim.running |> should.equal(True)
}

// --- Current frame ---

pub fn current_frame_0_at_start_test() {
  let anim = model.create(4)
  model.current_frame(anim) |> should.equal(0)
}

pub fn current_frame_1_after_200ms_test() {
  let anim = model.tick(model.create(4), 200.0)
  model.current_frame(anim) |> should.equal(1)
}

pub fn current_frame_2_after_400ms_test() {
  let anim = model.tick(model.create(4), 400.0)
  model.current_frame(anim) |> should.equal(2)
}

pub fn current_frame_wraps_after_cycle_test() {
  let anim = model.tick(model.create(4), 800.0)
  // 4 frames * 200ms = 800ms cycle
  model.current_frame(anim) |> should.equal(0)
}

pub fn current_frame_partial_progress_test() {
  let anim = model.tick(model.create(4), 100.0)
  // half of frame 0
  model.current_frame(anim) |> should.equal(0)
}

pub fn current_frame_custom_duration_test() {
  let anim = model.create_with_duration(4, 100.0)
  let anim = model.tick(anim, 150.0)
  // 100ms per frame, so 150ms = frame 1
  model.current_frame(anim) |> should.equal(1)
}

// --- Step frame ---

pub fn step_frame_advances_one_frame_test() {
  let anim = model.step_frame(model.create(4))
  model.current_frame(anim) |> should.equal(1)
}

pub fn step_frame_when_paused_test() {
  let anim = model.pause(model.create(4))
  let anim = model.step_frame(anim)
  let _ = anim.running |> should.equal(False)
  // still paused
  model.current_frame(anim) |> should.equal(1)
}

pub fn step_frame_multiple_times_test() {
  let anim = model.step_frame(model.step_frame(model.create(4)))
  model.current_frame(anim) |> should.equal(2)
}

pub fn step_frame_wraps_test() {
  let anim =
    model.step_frame(
      model.step_frame(model.step_frame(model.step_frame(model.create(4)))),
    )
  model.current_frame(anim) |> should.equal(0)
}

// --- Reset ---

pub fn reset_clears_elapsed_test() {
  let anim = model.tick(model.create(4), 500.0)
  let anim = model.reset(anim)
  anim.elapsed_ms |> should.equal(0.0)
}

pub fn reset_sets_running_test() {
  let anim = model.pause(model.create(4))
  let anim = model.reset(anim)
  anim.running |> should.equal(True)
}

pub fn reset_preserves_frame_duration_test() {
  let anim = model.create_with_duration(4, 100.0)
  let anim = model.tick(anim, 500.0)
  let anim = model.reset(anim)
  anim.frame_duration_ms |> should.equal(100.0)
}

// --- Speed adjustment ---

pub fn increase_speed_decreases_duration_test() {
  let anim = model.increase_speed(model.create(4))
  anim.frame_duration_ms |> should.equal(150.0)
}

pub fn decrease_speed_increases_duration_test() {
  let anim = model.decrease_speed(model.create(4))
  anim.frame_duration_ms |> should.equal(250.0)
}

pub fn increase_speed_clamped_at_min_test() {
  let anim = model.create_with_duration(4, 50.0)
  let anim = model.increase_speed(anim)
  anim.frame_duration_ms |> should.equal(50.0)
}

pub fn decrease_speed_clamped_at_max_test() {
  let anim = model.create_with_duration(4, 2000.0)
  let anim = model.decrease_speed(anim)
  anim.frame_duration_ms |> should.equal(2000.0)
}

pub fn multiple_speed_adjustments_test() {
  let anim = model.create(4)
  let anim = model.increase_speed(anim)
  // 150ms
  let anim = model.increase_speed(anim)
  // 100ms
  let anim = model.increase_speed(anim)
  // 50ms
  anim.frame_duration_ms |> should.equal(50.0)
}

// --- Helpers ---

pub fn fps_calculation_test() {
  let anim = model.create(4)
  assert_near(model.fps(anim), 5.0)
  // 200ms = 5 FPS
}

pub fn fps_with_custom_duration_test() {
  let anim = model.create_with_duration(4, 100.0)
  assert_near(model.fps(anim), 10.0)
  // 100ms = 10 FPS
}

pub fn is_running_test() {
  let anim = model.create(4)
  model.is_running(anim) |> should.equal(True)
  model.is_running(model.pause(anim)) |> should.equal(False)
}

pub fn get_elapsed_ms_test() {
  let anim = model.tick(model.create(4), 300.0)
  anim.elapsed_ms |> should.equal(300.0)
  model.get_elapsed_ms(anim) |> should.equal(300.0)
}

pub fn get_frame_duration_ms_test() {
  let anim = model.create(4)
  model.get_frame_duration_ms(anim) |> should.equal(200.0)
}

pub fn format_status_running_test() {
  let anim = model.create(4)
  let status = model.format_status(anim)
  status |> should.equal("frame: 0/4  running  5 FPS")
}

pub fn format_status_paused_test() {
  let anim = model.pause(model.create(4))
  let anim = model.tick(anim, 400.0)
  // paused, so no advance
  let anim = model.step_frame(anim)
  // manually step to frame 1
  let anim = model.step_frame(anim)
  // manually step to frame 2
  let status = model.format_status(anim)
  status |> should.equal("frame: 2/4  paused  5 FPS")
}

pub fn clamp_duration_bounds_test() {
  let _ = model.clamp_duration(30.0) |> should.equal(50.0)
  let _ = model.clamp_duration(5000.0) |> should.equal(2000.0)
  model.clamp_duration(150.0) |> should.equal(150.0)
}

fn assert_near(actual: Float, expected: Float) -> Nil {
  let diff = float.absolute_value(actual -. expected)
  { diff <. 0.01 } |> should.equal(True)
}
