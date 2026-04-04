import gleam/int
import gleam/list
import gleam/string
import opentui/buffer
import opentui/edit_buffer
import opentui/ffi
import opentui/renderer
import opentui/runtime

const bg_color = #(0.1, 0.1, 0.3, 1.0)

const fg_color = #(1.0, 1.0, 1.0, 1.0)

const title_bg = #(0.2, 0.4, 0.8, 1.0)

const status_bg = #(0.3, 0.3, 0.3, 1.0)

const editor_bg = #(0.05, 0.05, 0.15, 1.0)

const cursor_bg = #(0.9, 0.9, 0.9, 1.0)

const border_fg = #(0.4, 0.4, 0.6, 1.0)

const editor_x = 1

const editor_y = 2

const editor_w = 78

const editor_h = 19

const term_w = 80

const term_h = 24

pub fn main() -> Nil {
  let initial_text =
    "Welcome to the OpenTUI Gleam editor!\n\nType here. Press Enter for new lines.\nUse arrow keys to move the cursor.\nBackspace deletes. Ctrl+C or 'q' quits."

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
      runtime.log(msg)
      panic as "Failed to create renderer"
    }
  }

  renderer.setup(r, renderer.AlternateScreen)
  renderer.set_title(r, "OpenTUI Gleam Editor")
  renderer.enable_mouse(r, False)

  let eb = edit_buffer.create(0)
  edit_buffer.set_text(eb, initial_text)

  let r_int = ffi.renderer_to_int(r)
  runtime.run_editor_loop(r_int, fn(key) { handle_key(eb, key) }, fn() {
    render_frame(r, eb)
  })

  Nil
}

fn handle_key(eb: ffi.EditBuffer, key: String) -> Nil {
  case key {
    "\r" | "\n" -> edit_buffer.new_line(eb)
    "\u{7f}" | "\u{8}" -> edit_buffer.delete_backward(eb)
    "\u{1b}[D" -> edit_buffer.move_left(eb)
    "\u{1b}[C" -> edit_buffer.move_right(eb)
    "\u{1b}[A" -> edit_buffer.move_up(eb)
    "\u{1b}[B" -> edit_buffer.move_down(eb)
    _ -> {
      case string.length(key) > 0 {
        True -> edit_buffer.insert_char(eb, key)
        False -> Nil
      }
    }
  }
}

fn render_frame(r: ffi.Renderer, eb: ffi.EditBuffer) -> Nil {
  let buf = buffer.get_next_buffer(r)

  buffer.fill_rect(buf, 0, 0, term_w, term_h, bg_color)
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

  buffer.fill_rect(buf, editor_x, editor_y, editor_w, editor_h, editor_bg)
  draw_editor_border(buf)

  let text = edit_buffer.text(eb)
  let lines = string.split(text, "\n")

  lines
  |> list.index_map(fn(line, i) {
    case i < editor_h {
      True -> {
        let display = case string.length(line) > editor_w {
          True -> string.slice(line, 0, editor_w)
          False -> line
        }
        buffer.draw_text(
          buf,
          display,
          editor_x,
          editor_y + i,
          fg_color,
          editor_bg,
          0,
        )
      }
      False -> Nil
    }
  })
  |> fn(_) { Nil }()

  let #(row, col) = edit_buffer.cursor(eb)
  let cx = editor_x + col
  let cy = editor_y + row
  case cy < editor_y + editor_h && cx < editor_x + editor_w {
    True ->
      buffer.draw_text(
        buf,
        cursor_char(lines, row, col),
        cx,
        cy,
        editor_bg,
        cursor_bg,
        0,
      )
    False -> Nil
  }

  let status_y = term_h - 1
  buffer.fill_rect(buf, 0, status_y, term_w, 1, status_bg)
  let status =
    " Ln "
    <> int.to_string(row + 1)
    <> ", Col "
    <> int.to_string(col + 1)
    <> " "
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

  each_index(w, fn(i) {
    buffer.set_cell(buf, x + i, y, 0x2500, border_fg, bg_color, 0)
    buffer.set_cell(buf, x + i, y + h - 1, 0x2500, border_fg, bg_color, 0)
  })

  each_index(h, fn(i) {
    buffer.set_cell(buf, x, y + i, 0x2502, border_fg, bg_color, 0)
    buffer.set_cell(buf, x + w - 1, y + i, 0x2502, border_fg, bg_color, 0)
  })

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

fn cursor_char(lines: List(String), row: Int, col: Int) -> String {
  case line_at(lines, row) {
    Ok(line) ->
      case col < string.length(line) {
        True -> string.slice(line, col, 1)
        False -> " "
      }
    Error(_) -> " "
  }
}

fn line_at(lines: List(String), index: Int) -> Result(String, Nil) {
  case lines, index {
    [line, ..], 0 -> Ok(line)
    [_, ..rest], _ if index > 0 -> line_at(rest, index - 1)
    _, _ -> Error(Nil)
  }
}
