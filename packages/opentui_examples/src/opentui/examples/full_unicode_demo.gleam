import gleam/int
import gleam/list
import gleam/string
import opentui/buffer
import opentui/examples/common
import opentui/examples/phase2_state as state
import opentui/examples/phase4_model as model
import opentui/ffi
import opentui/grapheme
import opentui/types

pub fn main() -> Nil {
  let scroll = state.create_int(0)
  let lines = model.grapheme_test_lines()

  common.run_interactive_demo(
    "Full Unicode Demo",
    "Full Unicode Demo",
    fn(key) { handle_key(scroll, lines, key) },
    fn(buf) { draw(buf, scroll, lines) },
  )
}

fn handle_key(
  scroll: state.IntCell,
  lines: List(String),
  raw: String,
) -> Nil {
  let max_scroll = list.length(lines) - 1
  case raw {
    "\u{1b}[A" ->
      state.set_int(scroll, int.max(state.get_int(scroll) - 1, 0))
    "\u{1b}[B" ->
      state.set_int(scroll, int.min(state.get_int(scroll) + 1, max_scroll))
    _ -> Nil
  }
}

fn draw(
  buf: ffi.Buffer,
  scroll: state.IntCell,
  lines: List(String),
) -> Nil {
  let offset = state.get_int(scroll)

  common.draw_panel(buf, 2, 2, 76, 12, "Grapheme Rendering")
  draw_lines(buf, lines, offset, 4, 4, 0)

  common.draw_panel(buf, 2, 15, 76, 7, "Width Analysis")
  draw_widths(buf, lines, offset, 4, 17, 0)

  buffer.draw_text(
    buf,
    " ↑/↓ scroll  |  offset: " <> int.to_string(offset),
    4,
    common.term_h - 1,
    common.fg_color,
    common.status_bg,
    0,
  )
}

fn draw_lines(
  buf: ffi.Buffer,
  lines: List(String),
  offset: Int,
  x: Int,
  y: Int,
  i: Int,
) -> Nil {
  case lines {
    [] -> Nil
    [line, ..rest] -> {
      case i >= offset && i < offset + 8 {
        True -> {
          let chars = grapheme.encode(line, types.Normal)
          let _w =
            grapheme.draw_graphemes(
              buf,
              chars,
              x,
              y + i - offset,
              common.fg_color,
              common.panel_bg,
            )
          Nil
        }
        False -> Nil
      }
      draw_lines(buf, rest, offset, x, y, i + 1)
    }
  }
}

fn draw_widths(
  buf: ffi.Buffer,
  lines: List(String),
  offset: Int,
  x: Int,
  y: Int,
  i: Int,
) -> Nil {
  case lines {
    [] -> Nil
    [line, ..rest] -> {
      case i >= offset && i < offset + 4 {
        True -> {
          let char_count = string.length(line)
          let display_w = grapheme.display_width(line, types.Normal)
          let info =
            "chars="
            <> int.to_string(char_count)
            <> "  display_w="
            <> int.to_string(display_w)
            <> "  │ "
            <> string.slice(line, 0, 30)
          buffer.draw_text(
            buf,
            info,
            x,
            y + i - offset,
            common.muted_fg,
            common.panel_bg,
            0,
          )
        }
        False -> Nil
      }
      draw_widths(buf, rest, offset, x, y, i + 1)
    }
  }
}
