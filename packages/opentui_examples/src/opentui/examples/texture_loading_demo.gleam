import gleam/float
import gleam/int
import opentui/buffer
import opentui/examples/common
import opentui/examples/phase4_model as model
import opentui/examples/phase4_state as state
import opentui/ffi
import opentui/framebuffer

pub fn main() -> Nil {
  let time = state.create_float(0.0)

  common.run_animated_demo(
    "Texture Loading Demo",
    "Texture Loading Demo",
    fn(_key) { Nil },
    fn(dt) { state.set_float(time, state.get_float(time) +. dt) },
    fn(buf) { draw(buf, time) },
  )
}

fn draw(buf: ffi.Buffer, time: state.FloatCell) -> Nil {
  let t = state.get_float(time)

  common.draw_panel(buf, 2, 2, 76, 19, "Texture Loading (TUI Fallback)")

  // Simulate texture as a color grid using framebuffer
  let assert Ok(tex) = framebuffer.create(32, 12, "texture")
  draw_texture_grid(tex, t, 0, 0, 32, 12)
  framebuffer.draw_onto(buf, 5, 4, tex)
  framebuffer.destroy(tex)

  // Info
  buffer.draw_text(buf, "Procedural texture via hue cycling", 40, 5, common.fg_color, common.panel_bg, 0)
  buffer.draw_text(buf, "Each cell = one texel", 40, 7, common.muted_fg, common.panel_bg, 0)
  buffer.draw_text(buf, "Animated over time", 40, 9, common.muted_fg, common.panel_bg, 0)
  buffer.draw_text(
    buf,
    "t=" <> int.to_string(float.truncate(t)) <> "ms",
    40,
    11,
    common.accent_orange,
    common.panel_bg,
    1,
  )
  buffer.draw_text(buf, "Three.js not available — using", 40, 14, common.muted_fg, common.panel_bg, 0)
  buffer.draw_text(buf, "procedural color generation", 40, 15, common.muted_fg, common.panel_bg, 0)
}

fn draw_texture_grid(
  fb: ffi.Buffer,
  time: Float,
  x: Int,
  y: Int,
  w: Int,
  h: Int,
) -> Nil {
  draw_tex_rows(fb, time, x, y, w, h, 0)
}

fn draw_tex_rows(
  fb: ffi.Buffer,
  time: Float,
  x: Int,
  y: Int,
  w: Int,
  h: Int,
  row: Int,
) -> Nil {
  case row >= h {
    True -> Nil
    False -> {
      draw_tex_cols(fb, time, x, y, w, row, 0)
      draw_tex_rows(fb, time, x, y, w, h, row + 1)
    }
  }
}

fn draw_tex_cols(
  fb: ffi.Buffer,
  time: Float,
  x: Int,
  y: Int,
  w: Int,
  row: Int,
  col: Int,
) -> Nil {
  case col >= w {
    True -> Nil
    False -> {
      let hue =
        int.to_float({ col * 11 + row * 17 } % 360)
        +. time *. 0.03
      let #(r, g, b, _) = model.hue_to_rgb(hue)
      buffer.set_cell(
        fb,
        x + col,
        y + row,
        0x2588,
        #(r *. 0.7, g *. 0.7, b *. 0.7, 1.0),
        #(0.0, 0.0, 0.0, 0.0),
        0,
      )
      draw_tex_cols(fb, time, x, y, w, row, col + 1)
    }
  }
}
