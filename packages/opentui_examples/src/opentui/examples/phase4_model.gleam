import gleam/float
import gleam/int
import gleam/list
import gleam/string

// ---------------------------------------------------------------------------
// Vec2 / Physics
// ---------------------------------------------------------------------------

pub type Vec2 {
  Vec2(x: Float, y: Float)
}

pub fn vec2_add(a: Vec2, b: Vec2) -> Vec2 {
  Vec2(a.x +. b.x, a.y +. b.y)
}

pub fn vec2_scale(v: Vec2, s: Float) -> Vec2 {
  Vec2(v.x *. s, v.y *. s)
}

/// Bounce a position+velocity off walls. Returns (new_pos, new_vel).
pub fn bounce(
  pos: Float,
  vel: Float,
  min_bound: Float,
  max_bound: Float,
) -> #(Float, Float) {
  let new_pos = pos +. vel
  case new_pos <. min_bound {
    True -> #(min_bound, float.absolute_value(vel))
    False ->
      case new_pos >. max_bound {
        True -> #(max_bound, float.negate(float.absolute_value(vel)))
        False -> #(new_pos, vel)
      }
  }
}

/// Step a bouncing entity by dt seconds.
pub fn bounce_step(
  pos: Float,
  vel: Float,
  dt: Float,
  min_bound: Float,
  max_bound: Float,
) -> #(Float, Float) {
  bounce(pos, vel *. dt, min_bound, max_bound)
}

// ---------------------------------------------------------------------------
// Layer composition
// ---------------------------------------------------------------------------

pub type Layer {
  Layer(id: String, x: Int, y: Int, w: Int, h: Int, visible: Bool)
}

pub fn visible_layers(layers: List(Layer)) -> List(Layer) {
  list.filter(layers, fn(l) { l.visible })
}

pub fn move_layer(
  layers: List(Layer),
  id: String,
  dx: Int,
  dy: Int,
) -> List(Layer) {
  list.map(layers, fn(l) {
    case l.id == id {
      True -> Layer(..l, x: l.x + dx, y: l.y + dy)
      False -> l
    }
  })
}

pub fn toggle_layer(layers: List(Layer), id: String) -> List(Layer) {
  list.map(layers, fn(l) {
    case l.id == id {
      True -> Layer(..l, visible: !l.visible)
      False -> l
    }
  })
}

// ---------------------------------------------------------------------------
// Color math
// ---------------------------------------------------------------------------

pub fn lerp_float(from: Float, to: Float, t: Float) -> Float {
  from +. { to -. from } *. t
}

pub fn lerp_color(
  from: #(Float, Float, Float, Float),
  to: #(Float, Float, Float, Float),
  t: Float,
) -> #(Float, Float, Float, Float) {
  #(
    lerp_float(from.0, to.0, t),
    lerp_float(from.1, to.1, t),
    lerp_float(from.2, to.2, t),
    lerp_float(from.3, to.3, t),
  )
}

/// Convert a hue (0–360) to an RGBA color with full saturation and value.
pub fn hue_to_rgb(hue: Float) -> #(Float, Float, Float, Float) {
  let h = fmod(hue, 360.0) /. 60.0
  let sector = float.truncate(h)
  let f = h -. int.to_float(sector)
  let q = 1.0 -. f
  case sector % 6 {
    0 -> #(1.0, f, 0.0, 1.0)
    1 -> #(q, 1.0, 0.0, 1.0)
    2 -> #(0.0, 1.0, f, 1.0)
    3 -> #(0.0, q, 1.0, 1.0)
    4 -> #(f, 0.0, 1.0, 1.0)
    _ -> #(1.0, 0.0, q, 1.0)
  }
}

// ---------------------------------------------------------------------------
// Grapheme test lines (canonical wide-char samples)
// ---------------------------------------------------------------------------

pub fn grapheme_test_lines() -> List(String) {
  [
    "ASCII: Hello, World! 0123456789",
    "CJK: 東京都 北京市 서울시 大阪府",
    "Emoji: ★ ● ◆ ■ ▲ ♦ ♠ ♣ ♥",
    "Fractions: ½ ⅓ ¼ ⅛ ⅞",
    "Symbols: → ← ↑ ↓ ⇒ ⇐ ∞ ≈ ≠",
    "Box: ┌─┬─┐ │ │ └─┴─┘",
    "Math: ∑ ∏ ∫ √ ∂ ∇ ∆",
    "Currency: $ € £ ¥ ₹ ₿",
  ]
}

// ---------------------------------------------------------------------------
// Pattern generation
// ---------------------------------------------------------------------------

/// Generate a pattern character for position (x, y).
pub fn pattern_char(x: Int, y: Int) -> String {
  case { x + y } % 5 {
    0 -> "·"
    1 -> "+"
    2 -> "×"
    3 -> "○"
    _ -> "·"
  }
}

/// Generate a hue-cycling color for position (x, y).
pub fn pattern_color(x: Int, y: Int) -> #(Float, Float, Float, Float) {
  let hue = int.to_float({ x * 10 + y * 15 } % 360)
  let #(r, g, b, _) = hue_to_rgb(hue)
  #(r *. 0.3, g *. 0.3, b *. 0.3, 1.0)
}

// ---------------------------------------------------------------------------
// Utility: format float
// ---------------------------------------------------------------------------

pub fn float_to_string_1(f: Float) -> String {
  let whole = float.truncate(f)
  let frac = float.truncate({ f -. int.to_float(whole) } *. 10.0)
  int.to_string(whole) <> "." <> int.to_string(int.absolute_value(frac))
}

// ---------------------------------------------------------------------------
// Internals
// ---------------------------------------------------------------------------

fn fmod(a: Float, b: Float) -> Float {
  let div = float.truncate(a /. b)
  a -. int.to_float(div) *. b
}

/// Clamp an integer.
pub fn clamp_float(v: Float, lo: Float, hi: Float) -> Float {
  float.min(float.max(v, lo), hi)
}

/// Nth element of a string list, or default.
pub fn nth_or(items: List(String), index: Int, default: String) -> String {
  case items, index {
    [], _ -> default
    [item, ..], 0 -> item
    [_, ..rest], _ -> nth_or(rest, index - 1, default)
  }
}

/// Measure display width of a line using string.length (ASCII approximation).
pub fn approx_width(text: String) -> Int {
  string.length(text)
}
