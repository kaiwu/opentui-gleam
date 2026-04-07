import gleam/float
import gleam/list
import gleeunit/should
import opentui/examples/phase5_model as model
import opentui/math3d

pub fn cube_mesh_has_8_vertices_test() {
  let mesh = model.cube_mesh()
  model.vertex_count(mesh) |> should.equal(8)
}

pub fn cube_mesh_has_12_edges_test() {
  let mesh = model.cube_mesh()
  model.edge_count(mesh) |> should.equal(12)
}

pub fn pyramid_mesh_has_5_vertices_test() {
  let mesh = model.pyramid_mesh()
  model.vertex_count(mesh) |> should.equal(5)
}

pub fn pyramid_mesh_has_8_edges_test() {
  let mesh = model.pyramid_mesh()
  model.edge_count(mesh) |> should.equal(8)
}

pub fn mandelbrot_origin_inside_set_test() {
  // Origin (0,0) is inside the Mandelbrot set
  model.mandelbrot(0.0, 0.0, 50) |> should.equal(50)
}

pub fn mandelbrot_far_point_escapes_test() {
  // Point far from origin escapes quickly
  let result = model.mandelbrot(3.0, 3.0, 50)
  { result < 50 } |> should.equal(True)
}

pub fn mandelbrot_known_outside_test() {
  // (2, 0) is outside — |z| > 2 after first iteration
  let result = model.mandelbrot(2.0, 0.0, 50)
  { result < 10 } |> should.equal(True)
}

pub fn julia_boundary_escapes_test() {
  // A point far from origin with standard c
  let result = model.julia(2.0, 2.0, -0.7, 0.27015, 50)
  { result < 50 } |> should.equal(True)
}

pub fn fractal_color_inside_is_black_test() {
  let #(r, g, b, _a) = model.fractal_color(50, 50)
  let _ = r |> should.equal(0.0)
  let _ = g |> should.equal(0.0)
  b |> should.equal(0.0)
}

pub fn fractal_color_outside_is_colorful_test() {
  let #(r, g, b, _a) = model.fractal_color(10, 50)
  // Should have some color
  let total = r +. g +. b
  { total >. 0.0 } |> should.equal(True)
}

pub fn shade_char_dark_is_space_test() {
  model.shade_char(0.0) |> should.equal(0x20)
}

pub fn shade_char_bright_is_full_block_test() {
  model.shade_char(1.0) |> should.equal(0x2588)
}

pub fn sphere_points_not_empty_test() {
  let points = model.sphere_points(1.0, 4, 8)
  { points != [] } |> should.equal(True)
}

pub fn drag_rotation_idle_returns_zero_test() {
  let #(rx, ry) = model.drag_rotation(model.Idle, 10, 10)
  let _ = rx |> should.equal(0.0)
  ry |> should.equal(0.0)
}

pub fn drag_rotation_dragging_returns_delta_test() {
  let state = model.Dragging(10, 10, 0.0, 0.0)
  let #(rx, ry) = model.drag_rotation(state, 20, 15)
  // dx=10 -> ry = 10*0.02 = 0.2, dy=5 -> rx = 5*0.02 = 0.1
  let _ = assert_near(rx, 0.1)
  assert_near(ry, 0.2)
}

pub fn showcase_panels_returns_six_test() {
  list.length(model.showcase_panels()) |> should.equal(6)
}

pub fn line_points_horizontal_test() {
  let points = model.line_points(0, 0, 5, 0)
  { list.length(points) >= 5 } |> should.equal(True)
}

pub fn line_points_single_point_test() {
  let points = model.line_points(3, 3, 3, 3)
  list.length(points) |> should.equal(1)
}

fn assert_near(actual: Float, expected: Float) -> Nil {
  let diff = float.absolute_value(actual -. expected)
  { diff <. 0.01 } |> should.equal(True)
}
