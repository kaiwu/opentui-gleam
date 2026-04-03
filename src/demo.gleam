// src/demo.gleam
// Interactive text editor demo — type text, move cursor, backspace, enter

import gleam/string
import gleam/int
import gleam/list
import ffi
import renderer
import buffer

// ── Colors ──

const bg_color = #(0.1, 0.1, 0.3, 1.0)

const fg_color = #(1.0, 1.0, 1.0, 1.0)

const title_bg = #(0.2, 0.4, 0.8, 1.0)

const status_bg = #(0.3, 0.3, 0.3, 1.0)

const editor_bg = #(0.05, 0.05, 0.15, 1.0)

const cursor_bg = #(0.9, 0.9, 0.9, 1.0)

const border_fg = #(0.4, 0.4, 0.6, 1.0)

// ── Layout constants ──

const editor_x = 1

const editor_y = 2

const editor_w = 78

const editor_h = 19

const term_w = 80

const term_h = 24

// ── Main ──

pub fn main() -> Nil {
  let config =
    renderer.RendererConfig(
      width: term_w,
      height: term_h,
      screen_mode: renderer.AlternateScreen,
      exit_on_ctrl_c: True,
    )

  let r = case renderer.create(config) {
    Ok(r) -> r
    Error(msg) -> {
      ffi.log(msg)
      panic as "Failed to create renderer"
    }
  }

  renderer.setup(r, renderer.AlternateScreen)
  renderer.set_title(r, "OpenTUI Gleam Editor")
  renderer.enable_mouse(r, False)

  // Create edit buffer (no EditorView — we render text manually)
  let eb_ptr = ffi.create_edit_buffer(0)

  // Set initial text
  ffi.edit_buffer_set_text(
    eb_ptr,
    "Welcome to the OpenTUI Gleam editor!\n\nType here. Press Enter for new lines.\nUse arrow keys to move the cursor.\nBackspace deletes. Ctrl+C or 'q' quits.",
    180,
  )

  // Track cursor position in JS side, pass it back to us
  let r_int = ffi.renderer_to_int(r)
  ffi.run_editor_loop(
    r_int,
    fn(key) { handle_key(eb_ptr, key) },
    fn() { render_frame(r, eb_ptr) },
  )

  Nil
}

// ── Key handling ──

fn handle_key(eb_ptr: Int, key: String) -> Nil {
  case key {
    "\r" | "\n" -> ffi.edit_buffer_new_line(eb_ptr)
    "\u{7f}" | "\u{8}" -> ffi.edit_buffer_delete_char_backward(eb_ptr)
    "\u{1b}[D" -> ffi.edit_buffer_move_cursor_left(eb_ptr)
    "\u{1b}[C" -> ffi.edit_buffer_move_cursor_right(eb_ptr)
    "\u{1b}[A" -> ffi.edit_buffer_move_cursor_up(eb_ptr)
    "\u{1b}[B" -> ffi.edit_buffer_move_cursor_down(eb_ptr)
    _ -> {
      case string.length(key) > 0 {
        True -> ffi.edit_buffer_insert_char(eb_ptr, key, string.byte_size(key))
        False -> Nil
      }
    }
  }
}

// ── Rendering ──

fn render_frame(r: ffi.Renderer, eb_ptr: Int) -> Nil {
  let buf = buffer.get_next_buffer(r)

  // Background
  buffer.fill_rect(buf, 0, 0, term_w, term_h, bg_color)

  // Title bar
  buffer.fill_rect(buf, 0, 0, term_w, 1, title_bg)
  buffer.draw_text(
    buf,
    " Gleam Editor — type to edit, arrow keys to move, q to quit ",
    10,
    0,
    fg_color,
    title_bg,
    1,
  )

  // Editor background
  buffer.fill_rect(buf, editor_x, editor_y, editor_w, editor_h, editor_bg)

  // Editor border
  draw_editor_border(buf)

  // Get text from edit buffer and render lines
  let text = ffi.edit_buffer_get_text_as_string(eb_ptr)
  let lines = string.split(text, "\n")

  lines
  |> list.index_map(fn(line, i) {
    case i < editor_h {
      True -> {
        // Truncate long lines
        let display = case string.length(line) > editor_w {
          True -> string.slice(line, 0, editor_w)
          False -> line
        }
        buffer.draw_text(buf, display, editor_x, editor_y + i, fg_color, editor_bg, 0)
      }
      False -> Nil
    }
  })
  |> fn(_) { Nil }()

  // Get cursor position and draw cursor indicator
  let #(row, col) = ffi.edit_buffer_get_cursor(eb_ptr)
  let cx = editor_x + col
  let cy = editor_y + row
  case cy < editor_y + editor_h && cx < editor_x + editor_w {
    True -> buffer.fill_rect(buf, cx, cy, 1, 1, cursor_bg)
    False -> Nil
  }

  // Status bar
  let status_y = term_h - 1
  buffer.fill_rect(buf, 0, status_y, term_w, 1, status_bg)
  let status =
    " Ln " <> int.to_string(row + 1) <> ", Col " <> int.to_string(col + 1) <> " "
  buffer.draw_text(buf, status, 1, status_y, fg_color, status_bg, 0)
  buffer.draw_text(
    buf,
    " Ctrl+C or 'q' to quit ",
    term_w - 24,
    status_y,
    fg_color,
    status_bg,
    0,
  )

  // Corner decorations
  buffer.set_cell(buf, 0, 0, 0x250c, border_fg, bg_color, 0)
  buffer.set_cell(buf, term_w - 1, 0, 0x2510, border_fg, bg_color, 0)
  buffer.set_cell(buf, 0, term_h - 1, 0x2514, border_fg, bg_color, 0)
  buffer.set_cell(buf, term_w - 1, term_h - 1, 0x2518, border_fg, bg_color, 0)
}

fn draw_editor_border(buf: ffi.Buffer) -> Nil {
  let x = editor_x - 1
  let y = editor_y - 1
  let w = editor_w + 2
  let h = editor_h + 2
  // Top and bottom edges
  each_index(w, fn(i) {
    buffer.set_cell(buf, x + i, y, 0x2500, border_fg, bg_color, 0)
    buffer.set_cell(buf, x + i, y + h - 1, 0x2500, border_fg, bg_color, 0)
  })
  // Left and right edges
  each_index(h, fn(i) {
    buffer.set_cell(buf, x, y + i, 0x2502, border_fg, bg_color, 0)
    buffer.set_cell(buf, x + w - 1, y + i, 0x2502, border_fg, bg_color, 0)
  })
  // Corners
  buffer.set_cell(buf, x, y, 0x250c, border_fg, bg_color, 0)
  buffer.set_cell(buf, x + w - 1, y, 0x2510, border_fg, bg_color, 0)
  buffer.set_cell(buf, x, y + h - 1, 0x2514, border_fg, bg_color, 0)
  buffer.set_cell(buf, x + w - 1, y + h - 1, 0x2518, border_fg, bg_color, 0)
}

fn each_index(n: Int, f: fn(Int) -> Nil) -> Nil {
  list.repeat(0, n)
  |> list.index_map(fn(_zero, i) { f(i) })
  |> fn(_) { Nil }()
}
