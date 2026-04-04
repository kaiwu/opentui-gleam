import opentui/buffer
import opentui/examples/common
import opentui/ffi
import opentui/text

const sample_path = "/very/long/project/path/examples/opentui/demo/with/a/really/long/file-name.gleam"

const sample_sentence = "This is a very long line of demo text that should be truncated cleanly in a narrow panel."

pub fn main() -> Nil {
  common.run_static_demo(
    "Text Truncation Demo",
    "Gleam Text Truncation Demo",
    draw_body,
  )
}

fn draw_body(buf: ffi.Buffer) -> Nil {
  common.draw_panel(buf, 2, 3, 76, 18, "Truncation strategies")

  buffer.draw_text(buf, "Original:", 4, 6, common.fg_color, common.panel_bg, 1)
  buffer.draw_text(
    buf,
    text.truncate_end(sample_sentence, 64),
    14,
    6,
    common.fg_color,
    common.panel_bg,
    0,
  )

  buffer.draw_text(buf, "End:", 4, 9, common.fg_color, common.panel_bg, 1)
  buffer.draw_text(
    buf,
    text.truncate_end(sample_path, 52),
    14,
    9,
    common.fg_color,
    common.panel_bg,
    0,
  )

  buffer.draw_text(buf, "Middle:", 4, 12, common.fg_color, common.panel_bg, 1)
  buffer.draw_text(
    buf,
    text.truncate_middle(sample_path, 52),
    14,
    12,
    common.fg_color,
    common.panel_bg,
    0,
  )

  buffer.draw_text(
    buf,
    "These helpers are pure Gleam functions reused across demos.",
    4,
    16,
    common.fg_color,
    common.panel_bg,
    0,
  )
}
