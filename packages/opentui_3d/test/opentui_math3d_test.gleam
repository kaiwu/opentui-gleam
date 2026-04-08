import gleam/float
import gleeunit/should
import opentui/math3d.{Vec3}

pub fn vec3_add_test() {
  let r = math3d.vec3_add(Vec3(1.0, 2.0, 3.0), Vec3(4.0, 5.0, 6.0))
  let _ = r.x |> should.equal(5.0)
  let _ = r.y |> should.equal(7.0)
  r.z |> should.equal(9.0)
}

pub fn vec3_sub_test() {
  let r = math3d.vec3_sub(Vec3(5.0, 7.0, 9.0), Vec3(1.0, 2.0, 3.0))
  let _ = r.x |> should.equal(4.0)
  let _ = r.y |> should.equal(5.0)
  r.z |> should.equal(6.0)
}

pub fn vec3_scale_test() {
  let r = math3d.vec3_scale(Vec3(2.0, 3.0, 4.0), 0.5)
  let _ = r.x |> should.equal(1.0)
  let _ = r.y |> should.equal(1.5)
  r.z |> should.equal(2.0)
}

pub fn vec3_dot_test() {
  math3d.vec3_dot(Vec3(1.0, 0.0, 0.0), Vec3(0.0, 1.0, 0.0))
  |> should.equal(0.0)
}

pub fn vec3_dot_parallel_test() {
  math3d.vec3_dot(Vec3(1.0, 0.0, 0.0), Vec3(1.0, 0.0, 0.0))
  |> should.equal(1.0)
}

pub fn vec3_cross_x_y_test() {
  let r = math3d.vec3_cross(Vec3(1.0, 0.0, 0.0), Vec3(0.0, 1.0, 0.0))
  let _ = assert_near(r.x, 0.0)
  let _ = assert_near(r.y, 0.0)
  assert_near(r.z, 1.0)
}

pub fn vec3_cross_y_x_test() {
  let r = math3d.vec3_cross(Vec3(0.0, 1.0, 0.0), Vec3(1.0, 0.0, 0.0))
  assert_near(r.z, -1.0)
}

pub fn vec3_length_test() {
  assert_near(math3d.vec3_length(Vec3(3.0, 4.0, 0.0)), 5.0)
}

pub fn vec3_normalize_unit_test() {
  let r = math3d.vec3_normalize(Vec3(5.0, 0.0, 0.0))
  let _ = assert_near(r.x, 1.0)
  let _ = assert_near(r.y, 0.0)
  assert_near(r.z, 0.0)
}

pub fn vec3_normalize_zero_test() {
  let r = math3d.vec3_normalize(Vec3(0.0, 0.0, 0.0))
  r |> should.equal(Vec3(0.0, 0.0, 0.0))
}

pub fn rotate_y_zero_is_identity_test() {
  let v = Vec3(3.0, 4.0, 5.0)
  let r = math3d.rotate_y(v, 0.0)
  let _ = assert_near(r.x, 3.0)
  let _ = assert_near(r.y, 4.0)
  assert_near(r.z, 5.0)
}

pub fn rotate_y_360_is_identity_test() {
  let v = Vec3(3.0, 4.0, 5.0)
  let r = math3d.rotate_y(v, math3d.degrees_to_radians(360.0))
  let _ = assert_near(r.x, 3.0)
  let _ = assert_near(r.y, 4.0)
  assert_near(r.z, 5.0)
}

pub fn rotate_y_90_moves_x_to_neg_z_test() {
  let v = Vec3(1.0, 0.0, 0.0)
  let r = math3d.rotate_y(v, math3d.degrees_to_radians(90.0))
  let _ = assert_near(r.x, 0.0)
  assert_near(r.z, -1.0)
}

pub fn rotate_x_90_moves_y_to_z_test() {
  let v = Vec3(0.0, 1.0, 0.0)
  let r = math3d.rotate_x(v, math3d.degrees_to_radians(90.0))
  let _ = assert_near(r.y, 0.0)
  assert_near(r.z, 1.0)
}

pub fn project_center_point_test() {
  let camera = Vec3(0.0, 0.0, -5.0)
  let target = Vec3(0.0, 0.0, 0.0)
  let fov = math3d.degrees_to_radians(90.0)
  let #(sx, sy, depth) = math3d.project(Vec3(0.0, 0.0, 0.0), camera, target, fov, 80, 24)
  // Should project near center of viewport
  let _ = assert_near(sx, 40.0)
  let _ = assert_near(sy, 12.0)
  { depth >. 0.0 } |> should.equal(True)
}

pub fn project_behind_camera_test() {
  let camera = Vec3(0.0, 0.0, -5.0)
  let target = Vec3(0.0, 0.0, 0.0)
  let fov = math3d.degrees_to_radians(90.0)
  let #(sx, _sy, _depth) = math3d.project(Vec3(0.0, 0.0, -10.0), camera, target, fov, 80, 24)
  // Behind camera should return off-screen coordinates
  { sx <. -100.0 } |> should.equal(True)
}

pub fn vec3_lerp_boundaries_test() {
  let a = Vec3(0.0, 0.0, 0.0)
  let b = Vec3(10.0, 20.0, 30.0)
  let _ = math3d.vec3_lerp(a, b, 0.0) |> should.equal(a)
  math3d.vec3_lerp(a, b, 1.0) |> should.equal(b)
}

pub fn vec3_lerp_midpoint_test() {
  let a = Vec3(0.0, 0.0, 0.0)
  let b = Vec3(10.0, 20.0, 30.0)
  let r = math3d.vec3_lerp(a, b, 0.5)
  let _ = assert_near(r.x, 5.0)
  let _ = assert_near(r.y, 10.0)
  assert_near(r.z, 15.0)
}

pub fn degrees_to_radians_test() {
  assert_near(math3d.degrees_to_radians(180.0), math3d.pi())
}

pub fn sin_cos_identity_test() {
  // sin²(x) + cos²(x) = 1
  let x = 1.234
  let s = math3d.sin(x)
  let c = math3d.cos(x)
  assert_near(s *. s +. c *. c, 1.0)
}

fn assert_near(actual: Float, expected: Float) -> Nil {
  let diff = float.absolute_value(actual -. expected)
  { diff <. 0.01 } |> should.equal(True)
}
