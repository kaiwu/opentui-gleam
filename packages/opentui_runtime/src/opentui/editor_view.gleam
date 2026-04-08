import gleam/int
import gleam/string
import opentui/buffer
import opentui/edit_buffer
import opentui/ffi

pub fn create(eb: ffi.EditBuffer, width: Int, height: Int) -> ffi.EditorView {
  ffi.editor_view(ffi.create_editor_view(
    ffi.edit_buffer_to_int(eb),
    width,
    height,
  ))
}

pub fn destroy(view: ffi.EditorView) -> Nil {
  ffi.destroy_editor_view(ffi.editor_view_to_int(view))
}

pub fn set_viewport(
  view: ffi.EditorView,
  x: Int,
  y: Int,
  width: Int,
  height: Int,
  wrap: Bool,
) -> Nil {
  ffi.editor_view_set_viewport(
    ffi.editor_view_to_int(view),
    x,
    y,
    width,
    height,
    wrap,
  )
}

pub fn draw_to(buf: ffi.Buffer, view: ffi.EditorView, x: Int, y: Int) -> Nil {
  ffi.buffer_draw_editor_view(
    ffi.buffer_to_int(buf),
    ffi.editor_view_to_int(view),
    x,
    y,
  )
}

/// Configure the viewport and draw in one call.
pub fn render(
  buf: ffi.Buffer,
  view: ffi.EditorView,
  x: Int,
  y: Int,
  width: Int,
  height: Int,
  wrap: Bool,
) -> Nil {
  set_viewport(view, 0, 0, width, height, wrap)
  draw_to(buf, view, x, y)
}

/// Count logical lines in text (newline-separated).
pub fn line_count(text: String) -> Int {
  case string.length(text) {
    0 -> 1
    _ -> {
      let parts = string.split(text, "\n")
      list_length(parts)
    }
  }
}

fn list_length(items: List(a)) -> Int {
  do_list_length(items, 0)
}

fn do_list_length(items: List(a), acc: Int) -> Int {
  case items {
    [] -> acc
    [_, ..rest] -> do_list_length(rest, acc + 1)
  }
}

/// Calculate the gutter width needed to display line numbers for the given
/// number of total lines. Returns the character width (e.g. 3 for up to 999 lines).
pub fn gutter_width(total_lines: Int) -> Int {
  let digits = string.length(int.to_string(total_lines))
  int.max(digits, 2)
}

/// Draw line numbers into a buffer region. Renders right-aligned numbers
/// from `start_line` for `height` rows at position (`x`, `y`).
pub fn draw_line_numbers(
  buf: ffi.Buffer,
  x: Int,
  y: Int,
  width: Int,
  height: Int,
  start_line: Int,
  total_lines: Int,
  fg: #(Float, Float, Float, Float),
  bg: #(Float, Float, Float, Float),
) -> Nil {
  draw_line_numbers_loop(buf, x, y, width, height, start_line, total_lines, fg, bg, 0)
}

fn draw_line_numbers_loop(
  buf: ffi.Buffer,
  x: Int,
  y: Int,
  width: Int,
  height: Int,
  start_line: Int,
  total_lines: Int,
  fg: #(Float, Float, Float, Float),
  bg: #(Float, Float, Float, Float),
  row: Int,
) -> Nil {
  case row < height {
    False -> Nil
    True -> {
      let line_num = start_line + row
      case line_num <= total_lines {
        True -> {
          let num_str = int.to_string(line_num)
          let padded = string.pad_start(num_str, width, " ")
          buffer.draw_text(buf, padded, x, y + row, fg, bg, 0)
        }
        False -> Nil
      }
      draw_line_numbers_loop(buf, x, y, width, height, start_line, total_lines, fg, bg, row + 1)
    }
  }
}

/// Get the cursor position from the underlying edit buffer and compute
/// a scroll offset so the cursor stays visible within `viewport_height` rows.
/// Returns `#(cursor_row, cursor_col, scroll_offset)`.
pub fn cursor_scroll_state(
  eb: ffi.EditBuffer,
  viewport_height: Int,
  current_scroll: Int,
) -> #(Int, Int, Int) {
  let #(row, col) = edit_buffer.cursor(eb)
  let scroll = case row < current_scroll {
    True -> row
    False ->
      case row >= current_scroll + viewport_height {
        True -> row - viewport_height + 1
        False -> current_scroll
      }
  }
  #(row, col, scroll)
}
