import gleam/float
import gleeunit/should
import opentui/animation

pub fn create_timeline_test() {
  let tl = animation.create(1000.0, False)
  let _ = animation.progress(tl) |> should.equal(0.0)
  animation.is_done(tl) |> should.equal(False)
}

pub fn tick_advances_elapsed_test() {
  let tl = animation.create(1000.0, False)
  let tl2 = animation.tick(tl, 500.0)
  let p = animation.progress(tl2)
  assert_near(p, 0.5)
}

pub fn tick_clamps_at_duration_test() {
  let tl = animation.create(1000.0, False)
  let tl2 = animation.tick(tl, 2000.0)
  let _ = animation.progress(tl2) |> should.equal(1.0)
  animation.is_done(tl2) |> should.equal(True)
}

pub fn looping_wraps_test() {
  let tl = animation.create(1000.0, True)
  let tl2 = animation.tick(tl, 1500.0)
  let p = animation.progress(tl2)
  assert_near(p, 0.5)
  animation.is_done(tl2) |> should.equal(False)
}

pub fn tween_value_interpolates_test() {
  let tl =
    animation.create(1000.0, False)
    |> animation.add_tween("x", 0.0, animation.Tween(
      from: 10.0,
      to: 20.0,
      duration: 1000.0,
      easing: animation.linear,
    ))
  let tl2 = animation.tick(tl, 500.0)
  let v = animation.value(tl2, "x")
  assert_near(v, 15.0)
}

pub fn tween_before_offset_returns_from_test() {
  let tl =
    animation.create(2000.0, False)
    |> animation.add_tween("y", 1000.0, animation.Tween(
      from: 0.0,
      to: 100.0,
      duration: 1000.0,
      easing: animation.linear,
    ))
  let tl2 = animation.tick(tl, 500.0)
  let v = animation.value(tl2, "y")
  assert_near(v, 0.0)
}

pub fn linear_easing_test() {
  let _ = animation.linear(0.0) |> should.equal(0.0)
  let _ = animation.linear(0.5) |> should.equal(0.5)
  animation.linear(1.0) |> should.equal(1.0)
}

pub fn ease_in_out_boundaries_test() {
  let _ = animation.ease_in_out(0.0) |> should.equal(0.0)
  assert_near(animation.ease_in_out(1.0), 1.0)
}

pub fn ease_out_bounce_boundaries_test() {
  assert_near(animation.ease_out_bounce(0.0), 0.0)
  assert_near(animation.ease_out_bounce(1.0), 1.0)
}

pub fn lerp_test() {
  let _ = animation.lerp(0.0, 10.0, 0.0) |> should.equal(0.0)
  let _ = animation.lerp(0.0, 10.0, 1.0) |> should.equal(10.0)
  assert_near(animation.lerp(0.0, 10.0, 0.5), 5.0)
}

pub fn missing_tween_returns_zero_test() {
  let tl = animation.create(1000.0, False)
  animation.value(tl, "nonexistent") |> should.equal(0.0)
}

fn assert_near(actual: Float, expected: Float) -> Nil {
  let diff = float.absolute_value(actual -. expected)
  { diff <. 0.01 } |> should.equal(True)
}
