import gleam/float
import gleeunit/should
import opentui/physics2d.{type Body, type Vec2, Body, Circle, Rect, Vec2, World}

pub fn integrate_applies_gravity_test() {
  let body =
    Body(
      position: Vec2(5.0, 5.0),
      velocity: Vec2(0.0, 0.0),
      angle: 0.0,
      angular_velocity: 0.0,
      mass: 1.0,
      restitution: 0.8,
      shape: Circle(0.5),
    )
  let result = physics2d.integrate(body, Vec2(0.0, -9.8), 1.0)
  // Velocity should change by gravity
  assert_near(result.velocity.y, -9.8)
}

pub fn integrate_preserves_x_velocity_test() {
  let body =
    Body(
      position: Vec2(0.0, 0.0),
      velocity: Vec2(3.0, 0.0),
      angle: 0.0,
      angular_velocity: 0.0,
      mass: 1.0,
      restitution: 0.8,
      shape: Circle(0.5),
    )
  let result = physics2d.integrate(body, Vec2(0.0, -9.8), 1.0)
  // x velocity unchanged by vertical gravity
  assert_near(result.velocity.x, 3.0)
}

pub fn integrate_moves_position_test() {
  let body =
    Body(
      position: Vec2(0.0, 0.0),
      velocity: Vec2(5.0, 0.0),
      angle: 0.0,
      angular_velocity: 0.0,
      mass: 1.0,
      restitution: 0.8,
      shape: Circle(0.5),
    )
  let result = physics2d.integrate(body, Vec2(0.0, 0.0), 1.0)
  assert_near(result.position.x, 5.0)
}

pub fn constrain_bounces_at_bounds_test() {
  let body =
    Body(
      position: Vec2(-1.0, 5.0),
      velocity: Vec2(-5.0, 0.0),
      angle: 0.0,
      angular_velocity: 0.0,
      mass: 1.0,
      restitution: 1.0,
      shape: Circle(0.5),
    )
  let result = physics2d.constrain(body, #(0.0, 0.0, 100.0, 100.0))
  // Should bounce: velocity becomes positive
  { result.velocity.x >. 0.0 } |> should.equal(True)
}

pub fn constrain_interior_unchanged_test() {
  let body =
    Body(
      position: Vec2(50.0, 50.0),
      velocity: Vec2(3.0, -2.0),
      angle: 0.0,
      angular_velocity: 0.0,
      mass: 1.0,
      restitution: 1.0,
      shape: Circle(0.5),
    )
  let result = physics2d.constrain(body, #(0.0, 0.0, 100.0, 100.0))
  let _ = assert_near(result.velocity.x, 3.0)
  assert_near(result.velocity.y, -2.0)
}

pub fn collide_circles_separating_noop_test() {
  let a = make_body(Vec2(0.0, 0.0), Vec2(-1.0, 0.0), 0.5)
  let b = make_body(Vec2(5.0, 0.0), Vec2(1.0, 0.0), 0.5)
  let #(a_new, b_new) = physics2d.collide_circles(a, b)
  // Far apart — no collision
  let _ = assert_near(a_new.velocity.x, -1.0)
  assert_near(b_new.velocity.x, 1.0)
}

pub fn collide_circles_overlapping_resolves_test() {
  let a = make_body(Vec2(0.0, 0.0), Vec2(5.0, 0.0), 1.0)
  let b = make_body(Vec2(1.5, 0.0), Vec2(-5.0, 0.0), 1.0)
  let #(a_new, b_new) = physics2d.collide_circles(a, b)
  // After collision, a should be moving left-ish, b right-ish
  { a_new.velocity.x <. 5.0 } |> should.equal(True)
  { b_new.velocity.x >. -5.0 } |> should.equal(True)
}

pub fn step_zero_dt_preserves_state_test() {
  let world =
    World(
      bodies: [make_body(Vec2(10.0, 10.0), Vec2(1.0, 0.0), 0.5)],
      gravity: Vec2(0.0, 0.0),
      bounds: #(0.0, 0.0, 100.0, 100.0),
    )
  let stepped = physics2d.step(world, 0.0)
  case stepped.bodies {
    [b] -> {
      assert_near(b.position.x, 10.0)
      assert_near(b.position.y, 10.0)
    }
    _ -> panic as "expected 1 body"
  }
}

pub fn step_advances_position_test() {
  let world =
    World(
      bodies: [make_body(Vec2(10.0, 10.0), Vec2(10.0, 0.0), 0.5)],
      gravity: Vec2(0.0, 0.0),
      bounds: #(0.0, 0.0, 100.0, 100.0),
    )
  let stepped = physics2d.step(world, 0.05)
  case stepped.bodies {
    [b] -> { b.position.x >. 10.0 } |> should.equal(True)
    _ -> panic as "expected 1 body"
  }
}

pub fn create_world_and_add_body_test() {
  let world = physics2d.create_world(Vec2(0.0, -9.8), #(0.0, 0.0, 80.0, 24.0))
  let world =
    physics2d.add_body(world, make_body(Vec2(40.0, 12.0), Vec2(0.0, 0.0), 1.0))
  case world.bodies {
    [b] -> {
      assert_near(b.position.x, 40.0)
    }
    _ -> panic as "expected 1 body"
  }
}

pub fn rect_shape_has_nonzero_radius_test() {
  let body =
    Body(
      position: Vec2(0.0, 0.0),
      velocity: Vec2(0.0, 0.0),
      angle: 0.0,
      angular_velocity: 0.0,
      mass: 1.0,
      restitution: 0.8,
      shape: Rect(2.0, 3.0),
    )
  // Rect body should constrain properly (uses bounding circle)
  let result = physics2d.constrain(body, #(0.0, 0.0, 100.0, 100.0))
  // Position should be adjusted inward from (0,0) due to bounding radius
  { result.position.x >. 0.0 } |> should.equal(True)
}

fn make_body(pos: Vec2, vel: Vec2, radius: Float) -> Body {
  Body(
    position: pos,
    velocity: vel,
    angle: 0.0,
    angular_velocity: 0.0,
    mass: 1.0,
    restitution: 0.8,
    shape: Circle(radius),
  )
}

fn assert_near(actual: Float, expected: Float) -> Nil {
  let diff = float.absolute_value(actual -. expected)
  { diff <. 0.02 } |> should.equal(True)
}
