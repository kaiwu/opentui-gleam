import opentui/buffer
import opentui/examples/common
import opentui/ffi

pub fn main() -> Nil {
  common.run_static_demo("Transparency Demo", "Transparency Demo", draw)
}

fn draw(buf: ffi.Buffer) -> Nil {
  common.draw_panel(buf, 2, 3, 76, 18, "Alpha blending")
  draw_checkerboard(buf, 4, 5, 32, 12)
  buffer.fill_rect(buf, 8, 7, 14, 6, #(0.95, 0.36, 0.38, 0.35))
  buffer.fill_rect(buf, 16, 9, 14, 6, #(0.33, 0.57, 0.98, 0.45))
  buffer.fill_rect(buf, 24, 11, 14, 6, #(0.96, 0.82, 0.36, 0.55))
  buffer.draw_text(
    buf,
    "alpha 0.35",
    9,
    8,
    common.fg_color,
    #(0.0, 0.0, 0.0, 0.0),
    1,
  )
  buffer.draw_text(
    buf,
    "alpha 0.45",
    17,
    10,
    common.fg_color,
    #(0.0, 0.0, 0.0, 0.0),
    1,
  )
  buffer.draw_text(
    buf,
    "alpha 0.55",
    25,
    12,
    common.bg_color,
    #(0.0, 0.0, 0.0, 0.0),
    1,
  )

  common.draw_panel(buf, 42, 5, 32, 12, "Notes")
  buffer.draw_text(
    buf,
    "Transparent fills let lower pixels stay visible.",
    44,
    8,
    common.fg_color,
    common.panel_bg,
    0,
  )
  buffer.draw_text(
    buf,
    "This demo uses RGBA backgrounds directly through",
    44,
    10,
    common.fg_color,
    common.panel_bg,
    0,
  )
  buffer.draw_text(
    buf,
    "the runtime buffer wrapper.",
    44,
    11,
    common.fg_color,
    common.panel_bg,
    0,
  )
}

fn draw_checkerboard(buf: ffi.Buffer, x: Int, y: Int, w: Int, h: Int) -> Nil {
  common.each_index(h, fn(row) {
    common.each_index(w, fn(col) {
      let even = remainder(row + col, 2) == 0
      let shade = case even {
        True -> #(0.18, 0.2, 0.24, 1.0)
        False -> #(0.11, 0.13, 0.18, 1.0)
      }
      buffer.fill_rect(buf, x + col, y + row, 1, 1, shade)
    })
  })
}

fn remainder(value: Int, modulus: Int) -> Int {
  value % modulus
}
