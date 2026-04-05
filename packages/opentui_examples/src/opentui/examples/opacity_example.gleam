import opentui/buffer
import opentui/examples/common
import opentui/ffi

pub fn main() -> Nil {
  common.run_static_demo("Opacity Example", "Opacity Example", draw)
}

fn draw(buf: ffi.Buffer) -> Nil {
  common.draw_panel(buf, 2, 3, 76, 18, "Opacity stack")
  draw_card(buf, 8, 7, "1.00", common.accent_blue)

  buffer.push_opacity(buf, 0.65)
  draw_card(buf, 29, 7, "0.65", common.accent_green)
  buffer.pop_opacity(buf)

  buffer.push_opacity(buf, 0.35)
  draw_card(buf, 50, 7, "0.35", common.accent_pink)
  buffer.push_opacity(buf, 0.6)
  buffer.fill_rect(buf, 56, 11, 7, 3, common.accent_yellow)
  buffer.draw_text(
    buf,
    "nested",
    57,
    12,
    common.bg_color,
    common.accent_yellow,
    1,
  )
  buffer.pop_opacity(buf)
  buffer.pop_opacity(buf)

  buffer.draw_text(
    buf,
    "push_opacity scales every draw call until pop_opacity restores the previous stack frame.",
    6,
    18,
    common.fg_color,
    common.bg_color,
    0,
  )
}

fn draw_card(
  buf: ffi.Buffer,
  x: Int,
  y: Int,
  label: String,
  bg: #(Float, Float, Float, Float),
) -> Nil {
  buffer.fill_rect(buf, x, y, 16, 8, bg)
  buffer.draw_text(buf, "Opacity", x + 4, y + 2, common.bg_color, bg, 1)
  buffer.draw_text(buf, label, x + 6, y + 4, common.bg_color, bg, 1)
}
