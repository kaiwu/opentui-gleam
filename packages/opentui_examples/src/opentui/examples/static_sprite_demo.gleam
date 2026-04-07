import gleam/float
import gleam/int
import opentui/buffer
import opentui/examples/common
import opentui/examples/phase4_model as model
import opentui/examples/phase4_state as state
import opentui/ffi
import opentui/framebuffer

pub fn main() -> Nil {
  let hue = state.create_float(0.0)

  common.run_animated_demo(
    "Static Sprite Demo",
    "Static Sprite Demo",
    fn(_key) { Nil },
    fn(dt) { state.set_float(hue, model.clamp_float(state.get_float(hue) +. dt *. 0.05, 0.0, 360.0)) },
    fn(buf) { draw(buf, hue) },
  )
}

fn draw(buf: ffi.Buffer, hue: state.FloatCell) -> Nil {
  let h = state.get_float(hue)
  let hue_val = case h >=. 360.0 {
    True -> h -. 360.0
    False -> h
  }
  state.set_float(hue, hue_val)

  common.draw_panel(buf, 2, 2, 76, 19, "Static Sprite (TUI Fallback)")

  // Draw a sprite-like character using a framebuffer
  let assert Ok(sprite) = framebuffer.create(16, 9, "sprite")
  let color = model.hue_to_rgb(hue_val)
  draw_sprite_pixels(sprite, color)
  framebuffer.draw_onto(buf, 10, 5, sprite)
  framebuffer.destroy(sprite)

  // Info panel
  buffer.draw_text(buf, "Sprite rendered as framebuffer cells", 32, 6, common.fg_color, common.panel_bg, 0)
  buffer.draw_text(buf, "Color cycles via hue rotation", 32, 8, common.muted_fg, common.panel_bg, 0)
  buffer.draw_text(
    buf,
    "hue: " <> int.to_string(float.truncate(hue_val)) <> "°",
    32,
    10,
    common.accent_blue,
    common.panel_bg,
    1,
  )
  buffer.draw_text(buf, "Three.js not available — using", 32, 13, common.muted_fg, common.panel_bg, 0)
  buffer.draw_text(buf, "TUI framebuffer compositing", 32, 14, common.muted_fg, common.panel_bg, 0)
}

fn draw_sprite_pixels(
  fb: ffi.Buffer,
  color: #(Float, Float, Float, Float),
) -> Nil {
  // Simple diamond sprite pattern
  let pattern = [
    #(7, 0), #(8, 0),
    #(6, 1), #(7, 1), #(8, 1), #(9, 1),
    #(5, 2), #(6, 2), #(7, 2), #(8, 2), #(9, 2), #(10, 2),
    #(4, 3), #(5, 3), #(6, 3), #(7, 3), #(8, 3), #(9, 3), #(10, 3), #(11, 3),
    #(3, 4), #(4, 4), #(5, 4), #(6, 4), #(7, 4), #(8, 4), #(9, 4), #(10, 4), #(11, 4), #(12, 4),
    #(4, 5), #(5, 5), #(6, 5), #(7, 5), #(8, 5), #(9, 5), #(10, 5), #(11, 5),
    #(5, 6), #(6, 6), #(7, 6), #(8, 6), #(9, 6), #(10, 6),
    #(6, 7), #(7, 7), #(8, 7), #(9, 7),
    #(7, 8), #(8, 8),
  ]
  draw_pixels(fb, pattern, color)
}

fn draw_pixels(
  fb: ffi.Buffer,
  pixels: List(#(Int, Int)),
  color: #(Float, Float, Float, Float),
) -> Nil {
  case pixels {
    [] -> Nil
    [#(x, y), ..rest] -> {
      buffer.set_cell(fb, x, y, 0x2588, color, #(0.0, 0.0, 0.0, 0.0), 0)
      draw_pixels(fb, rest, color)
    }
  }
}
