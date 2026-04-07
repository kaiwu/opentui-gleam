import gleam/float
import gleam/list
import gleeunit/should
import opentui/examples/phase4_model as model

// --- Vec2 ---

pub fn vec2_add_test() {
  let r = model.vec2_add(model.Vec2(1.0, 2.0), model.Vec2(3.0, 4.0))
  let _ = r.x |> should.equal(4.0)
  r.y |> should.equal(6.0)
}

pub fn vec2_scale_test() {
  let r = model.vec2_scale(model.Vec2(2.0, 3.0), 0.5)
  let _ = r.x |> should.equal(1.0)
  r.y |> should.equal(1.5)
}

// --- Bounce ---

pub fn bounce_reflects_at_min_test() {
  let #(pos, vel) = model.bounce(1.0, -5.0, 0.0, 100.0)
  let _ = pos |> should.equal(0.0)
  { vel >. 0.0 } |> should.equal(True)
}

pub fn bounce_reflects_at_max_test() {
  let #(pos, vel) = model.bounce(98.0, 5.0, 0.0, 100.0)
  let _ = pos |> should.equal(100.0)
  { vel <. 0.0 } |> should.equal(True)
}

pub fn bounce_passes_through_interior_test() {
  let #(pos, vel) = model.bounce(50.0, 3.0, 0.0, 100.0)
  let _ = pos |> should.equal(53.0)
  vel |> should.equal(3.0)
}

pub fn bounce_step_scales_by_dt_test() {
  let #(pos, _vel) = model.bounce_step(10.0, 5.0, 2.0, 0.0, 100.0)
  assert_near(pos, 20.0)
}

// --- Layer ---

pub fn visible_layers_filters_test() {
  let layers = [
    model.Layer("a", 0, 0, 10, 10, True),
    model.Layer("b", 0, 0, 10, 10, False),
    model.Layer("c", 0, 0, 10, 10, True),
  ]
  model.visible_layers(layers) |> list.length |> should.equal(2)
}

pub fn move_layer_adjusts_position_test() {
  let layers = [model.Layer("a", 5, 5, 10, 10, True)]
  let moved = model.move_layer(layers, "a", 3, -2)
  case moved {
    [l] -> {
      let _ = l.x |> should.equal(8)
      l.y |> should.equal(3)
    }
    _ -> panic as "expected 1 layer"
  }
}

pub fn toggle_layer_flips_visibility_test() {
  let layers = [model.Layer("a", 0, 0, 10, 10, True)]
  let toggled = model.toggle_layer(layers, "a")
  case toggled {
    [l] -> l.visible |> should.equal(False)
    _ -> panic as "expected 1 layer"
  }
}

// --- Color math ---

pub fn lerp_float_boundaries_test() {
  let _ = model.lerp_float(0.0, 10.0, 0.0) |> should.equal(0.0)
  model.lerp_float(0.0, 10.0, 1.0) |> should.equal(10.0)
}

pub fn lerp_float_midpoint_test() {
  assert_near(model.lerp_float(0.0, 10.0, 0.5), 5.0)
}

pub fn lerp_color_test() {
  let from = #(0.0, 0.0, 0.0, 1.0)
  let to = #(1.0, 1.0, 1.0, 1.0)
  let result = model.lerp_color(from, to, 0.5)
  assert_near(result.0, 0.5)
  assert_near(result.1, 0.5)
  assert_near(result.2, 0.5)
  assert_near(result.3, 1.0)
}

pub fn hue_to_rgb_red_test() {
  let #(r, g, _b, a) = model.hue_to_rgb(0.0)
  let _ = r |> should.equal(1.0)
  let _ = assert_near(g, 0.0)
  a |> should.equal(1.0)
}

pub fn hue_to_rgb_green_test() {
  let #(_r, g, _b, _a) = model.hue_to_rgb(120.0)
  assert_near(g, 1.0)
}

// --- Pattern ---

pub fn pattern_char_returns_valid_chars_test() {
  let c = model.pattern_char(0, 0)
  let valid = c == "·" || c == "+" || c == "×" || c == "○"
  valid |> should.equal(True)
}

pub fn pattern_color_returns_rgba_test() {
  let #(r, g, b, a) = model.pattern_color(5, 5)
  let _ = { r >=. 0.0 && r <=. 1.0 } |> should.equal(True)
  let _ = { g >=. 0.0 && g <=. 1.0 } |> should.equal(True)
  let _ = { b >=. 0.0 && b <=. 1.0 } |> should.equal(True)
  a |> should.equal(1.0)
}

// --- Grapheme test lines ---

pub fn grapheme_test_lines_not_empty_test() {
  let lines = model.grapheme_test_lines()
  { lines != [] } |> should.equal(True)
}

// --- Utility ---

pub fn float_to_string_1_test() {
  model.float_to_string_1(3.7) |> should.equal("3.7")
}

pub fn clamp_float_test() {
  let _ = model.clamp_float(5.0, 0.0, 10.0) |> should.equal(5.0)
  let _ = model.clamp_float(-1.0, 0.0, 10.0) |> should.equal(0.0)
  model.clamp_float(15.0, 0.0, 10.0) |> should.equal(10.0)
}

pub fn nth_or_returns_element_test() {
  model.nth_or(["a", "b", "c"], 1, "?") |> should.equal("b")
}

pub fn nth_or_returns_default_test() {
  model.nth_or(["a"], 5, "?") |> should.equal("?")
}

pub fn approx_width_test() {
  model.approx_width("hello") |> should.equal(5)
}

fn assert_near(actual: Float, expected: Float) -> Nil {
  let diff = float.absolute_value(actual -. expected)
  { diff <. 0.01 } |> should.equal(True)
}
