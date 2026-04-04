import gleam/list
import opentui/buffer
import opentui/examples/common
import opentui/ffi
import opentui/text

const sample = "Gleam makes layout helpers easy to compose as pure functions. This demo shows the same paragraph rendered with no wrap, word wrap, and character wrap."

pub fn main() -> Nil {
  common.run_static_demo("Text Wrap Demo", "Gleam Text Wrap Demo", draw_body)
}

fn draw_body(buf: ffi.Buffer) -> Nil {
  common.draw_panel(buf, 2, 3, 24, 18, "No wrap")
  common.draw_panel(buf, 28, 3, 24, 18, "Word wrap")
  common.draw_panel(buf, 54, 3, 24, 18, "Character wrap")

  draw_lines(buf, 4, 5, text.wrap(sample, 18, text.NoWrap))
  draw_lines(buf, 30, 5, text.wrap(sample, 18, text.WordWrap))
  draw_lines(buf, 56, 5, text.wrap(sample, 18, text.CharacterWrap))
}

fn draw_lines(buf: ffi.Buffer, x: Int, y: Int, lines: List(String)) -> Nil {
  lines
  |> list.index_map(fn(line, i) {
    case i < 14 {
      True ->
        buffer.draw_text(
          buf,
          text.truncate_end(line, 18),
          x,
          y + i,
          common.fg_color,
          common.panel_bg,
          0,
        )
      False -> Nil
    }
  })
  |> fn(_) { Nil }()
}
