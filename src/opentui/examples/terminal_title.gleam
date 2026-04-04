import opentui/buffer
import opentui/examples/common
import opentui/ffi

pub fn main() -> Nil {
  common.run_static_demo(
    "Terminal Title Demo",
    "Gleam Terminal Title Demo",
    draw_body,
  )
}

fn draw_body(buf: ffi.Buffer) -> Nil {
  common.draw_panel(buf, 2, 3, 76, 16, "Terminal Title")
  buffer.draw_text(
    buf,
    "The terminal title for this demo was set from Gleam.",
    4,
    6,
    common.fg_color,
    common.panel_bg,
    0,
  )
  buffer.draw_text(
    buf,
    "This mirrors the TypeScript terminal-title example",
    4,
    8,
    common.fg_color,
    common.panel_bg,
    0,
  )
  buffer.draw_text(
    buf,
    "using the Gleam renderer API.",
    4,
    10,
    common.fg_color,
    common.panel_bg,
    0,
  )
  buffer.draw_text(
    buf,
    "Check your terminal tab or window title while this demo is open.",
    4,
    12,
    common.fg_color,
    common.panel_bg,
    0,
  )
}
