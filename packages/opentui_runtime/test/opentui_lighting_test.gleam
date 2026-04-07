import gleam/float
import gleeunit/should
import opentui/lighting
import opentui/math3d.{Vec3}

pub fn phong_facing_max_intensity_test() {
  // Normal facing directly toward light
  let normal = Vec3(0.0, 0.0, 1.0)
  let light_dir = Vec3(0.0, 0.0, 1.0)
  let view_dir = Vec3(0.0, 0.0, 1.0)
  let result = lighting.phong(normal, light_dir, view_dir, 32.0)
  // diffuse=1.0 + specular (reflect aligns with view)
  { result >=. 1.0 } |> should.equal(True)
}

pub fn phong_perpendicular_zero_test() {
  // Light perpendicular to normal
  let normal = Vec3(0.0, 0.0, 1.0)
  let light_dir = Vec3(1.0, 0.0, 0.0)
  let view_dir = Vec3(0.0, 0.0, 1.0)
  let result = lighting.phong(normal, light_dir, view_dir, 32.0)
  assert_near(result, 0.0)
}

pub fn phong_behind_surface_zero_test() {
  // Light behind the surface
  let normal = Vec3(0.0, 0.0, 1.0)
  let light_dir = Vec3(0.0, 0.0, -1.0)
  let view_dir = Vec3(0.0, 0.0, 1.0)
  let result = lighting.phong(normal, light_dir, view_dir, 32.0)
  assert_near(result, 0.0)
}

pub fn diffuse_facing_test() {
  let result = lighting.diffuse(Vec3(0.0, 1.0, 0.0), Vec3(0.0, 1.0, 0.0))
  assert_near(result, 1.0)
}

pub fn diffuse_perpendicular_test() {
  let result = lighting.diffuse(Vec3(0.0, 1.0, 0.0), Vec3(1.0, 0.0, 0.0))
  assert_near(result, 0.0)
}

pub fn ambient_always_contributes_test() {
  let lights = [lighting.AmbientLight(#(1.0, 1.0, 1.0), 0.3)]
  let #(r, g, b) =
    lighting.illuminate(
      lights,
      Vec3(0.0, 0.0, 0.0),
      Vec3(0.0, 1.0, 0.0),
      Vec3(0.0, 0.0, 5.0),
      32.0,
    )
  let _ = assert_near(r, 0.3)
  let _ = assert_near(g, 0.3)
  assert_near(b, 0.3)
}

pub fn directional_plus_ambient_test() {
  let lights = [
    lighting.AmbientLight(#(1.0, 1.0, 1.0), 0.1),
    lighting.DirectionalLight(Vec3(0.0, -1.0, 0.0), #(1.0, 1.0, 1.0), 1.0),
  ]
  let #(r, _g, _b) =
    lighting.illuminate(
      lights,
      Vec3(0.0, 0.0, 0.0),
      Vec3(0.0, 1.0, 0.0),
      Vec3(0.0, 5.0, 0.0),
      32.0,
    )
  // Should be ambient(0.1) + directional contribution > 0.1
  { r >. 0.1 } |> should.equal(True)
}

pub fn point_light_out_of_range_test() {
  let lights = [
    lighting.PointLight(Vec3(100.0, 100.0, 100.0), #(1.0, 0.0, 0.0), 1.0, 5.0),
  ]
  let #(r, _g, _b) =
    lighting.illuminate(
      lights,
      Vec3(0.0, 0.0, 0.0),
      Vec3(0.0, 1.0, 0.0),
      Vec3(0.0, 0.0, 5.0),
      32.0,
    )
  assert_near(r, 0.0)
}

pub fn illuminate_empty_lights_test() {
  let #(r, g, b) =
    lighting.illuminate(
      [],
      Vec3(0.0, 0.0, 0.0),
      Vec3(0.0, 1.0, 0.0),
      Vec3(0.0, 0.0, 5.0),
      32.0,
    )
  let _ = r |> should.equal(0.0)
  let _ = g |> should.equal(0.0)
  b |> should.equal(0.0)
}

fn assert_near(actual: Float, expected: Float) -> Nil {
  let diff = float.absolute_value(actual -. expected)
  { diff <. 0.01 } |> should.equal(True)
}
