import gleam/string
import opentui/buffer
import opentui/edit_buffer
import opentui/editor_view
import opentui/examples/editor_demo_model as model
import opentui/examples/phase2_state as state
import opentui/ffi
import opentui/input
import opentui/renderer
import opentui/runtime

const bg_color = #(0.1, 0.1, 0.3, 1.0)

const fg_color = #(1.0, 1.0, 1.0, 1.0)

const title_bg = #(0.2, 0.4, 0.8, 1.0)

const status_bg = #(0.3, 0.3, 0.3, 1.0)

const editor_bg = #(0.05, 0.05, 0.15, 1.0)

const cursor_bg = #(0.9, 0.9, 0.9, 1.0)

const gutter_bg = #(0.09, 0.11, 0.18, 1.0)

const border_fg = #(0.4, 0.4, 0.6, 1.0)

const gutter_fg = #(0.6, 0.63, 0.7, 1.0)

const editor_x = 1

const editor_y = 2

const editor_w = 78

const editor_h = 19

const term_w = 80

const term_h = 24

pub fn main() -> Nil {
  let initial_text =
    "Welcome to the OpenTUI Gleam editor!\n\nThis is an interactive text editor powered by EditBuffer and EditorView.\n\nType here. Press Enter for new lines.\nUse arrow keys to move the cursor.\nShift+W toggles wrap mode.\nShift+L toggles line numbers.\nCtrl+D deletes forward.\nBackspace deletes backward."

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

  let wrap_mode = state.create_int(0)
  let show_line_numbers = state.create_bool(True)
  let view = editor_view.create(eb, editor_w, editor_h)

  input.run_event_loop(
    r,
    fn(event) {
      case event {
        input.KeyEvent(raw, key) ->
          handle_key(eb, wrap_mode, show_line_numbers, raw, key)
        input.UnknownEvent(raw) ->
          handle_key(
            eb,
            wrap_mode,
            show_line_numbers,
            raw,
            input.UnknownKey(raw),
          )
        input.MouseEvent(_) -> Nil
      }
    },
    fn() { render_frame(r, eb, view, wrap_mode, show_line_numbers) },
  )

  editor_view.destroy(view)
  Nil
}

fn handle_key(
  eb: ffi.EditBuffer,
  wrap_mode: state.IntCell,
  show_line_numbers: state.BoolCell,
  raw: String,
  key: input.Key,
) -> Nil {
  case key {
    input.Enter -> edit_buffer.new_line(eb)
    input.Backspace -> edit_buffer.delete_backward(eb)
    input.ArrowLeft -> edit_buffer.move_left(eb)
    input.ArrowRight -> edit_buffer.move_right(eb)
    input.ArrowUp -> edit_buffer.move_up(eb)
    input.ArrowDown -> edit_buffer.move_down(eb)
    input.Character("W") ->
      state.set_int(wrap_mode, next_wrap_mode_index(state.get_int(wrap_mode)))
    input.Character("L") ->
      state.set_bool(show_line_numbers, !state.get_bool(show_line_numbers))
    _ ->
      case raw {
        "\u{4}" -> edit_buffer.delete_forward(eb)
        _ ->
          case string.length(raw) > 0 && is_printable_text(raw) {
            True -> edit_buffer.insert_char(eb, raw)
            False -> Nil
          }
      }
  }
}

fn render_frame(
  r: ffi.Renderer,
  eb: ffi.EditBuffer,
  view: ffi.EditorView,
  wrap_mode: state.IntCell,
  show_line_numbers: state.BoolCell,
) -> Nil {
  let buf = buffer.get_next_buffer(r)
  let mode = wrap_mode_from_index(state.get_int(wrap_mode))
  let show_numbers = state.get_bool(show_line_numbers)
  let text = edit_buffer.text(eb)
  let total_lines = model.logical_line_count(text)
  let gutter_w = case show_numbers {
    True -> model.gutter_width(total_lines)
    False -> 0
  }
  let content_x =
    editor_x
    + gutter_w
    + case show_numbers {
      True -> 2
      False -> 0
    }
  let content_w =
    editor_w
    - gutter_w
    - case show_numbers {
      True -> 2
      False -> 0
    }

  buffer.fill_rect(buf, 0, 0, term_w, term_h, bg_color)
  buffer.fill_rect(buf, 0, 0, term_w, 1, title_bg)
  buffer.draw_text(
    buf,
    " Gleam Editor — Shift+W wrap, Shift+L lines, Ctrl+D delete forward ",
    4,
    0,
    fg_color,
    title_bg,
    1,
  )

  buffer.fill_rect(buf, editor_x, editor_y, editor_w, editor_h, editor_bg)
  draw_editor_border(buf)

  case show_numbers {
    True -> draw_line_number_gutter(buf, text, content_w, mode, gutter_w)
    False -> Nil
  }

  case model.use_editor_view(mode) {
    True -> {
      editor_view.set_viewport(
        view,
        0,
        0,
        content_w,
        editor_h,
        model.editor_view_wrap(mode),
      )
      editor_view.draw_to(buf, view, content_x, editor_y)
    }
    False -> draw_character_wrap_content(buf, text, content_x, content_w)
  }

  case mode {
    model.CharacterWrap ->
      draw_character_wrap_cursor(buf, text, eb, content_x, content_w)
    _ -> Nil
  }

  let #(row, col) = edit_buffer.cursor(eb)
  let status =
    model.status_text(
      row,
      col,
      mode,
      show_numbers,
      edit_buffer.can_undo(eb),
      edit_buffer.can_redo(eb),
    )
  let quit_hint = " Ctrl+C or 'q' to quit "
  let status = model.fit_status(status, term_w - string.length(quit_hint) - 2)

  let status_y = term_h - 1
  buffer.fill_rect(buf, 0, status_y, term_w, 1, status_bg)
  buffer.draw_text(buf, status, 1, status_y, fg_color, status_bg, 0)
  buffer.draw_text(
    buf,
    quit_hint,
    term_w - string.length(quit_hint),
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

fn draw_line_number_gutter(
  buf: ffi.Buffer,
  text: String,
  content_w: Int,
  mode: model.WrapMode,
  gutter_w: Int,
) -> Nil {
  let rows = model.line_number_rows(text, content_w, mode)
  each_index(editor_h, fn(i) {
    buffer.fill_rect(buf, editor_x, editor_y + i, gutter_w, 1, gutter_bg)
    buffer.set_cell(
      buf,
      editor_x + gutter_w,
      editor_y + i,
      0x2502,
      border_fg,
      editor_bg,
      0,
    )
    case line_at(rows, i) {
      Ok(label) ->
        buffer.draw_text(
          buf,
          string.pad_start(label, gutter_w, " "),
          editor_x,
          editor_y + i,
          gutter_fg,
          gutter_bg,
          0,
        )
      Error(_) -> Nil
    }
  })
}

fn draw_character_wrap_content(
  buf: ffi.Buffer,
  text: String,
  content_x: Int,
  content_w: Int,
) -> Nil {
  draw_character_wrap_lines(
    buf,
    model.visual_lines(text, content_w, model.CharacterWrap),
    content_x,
    0,
  )
}

fn draw_character_wrap_lines(
  buf: ffi.Buffer,
  lines: List(String),
  content_x: Int,
  index: Int,
) -> Nil {
  case lines, index < editor_h {
    [line, ..rest], True -> {
      buffer.draw_text(
        buf,
        line,
        content_x,
        editor_y + index,
        fg_color,
        editor_bg,
        0,
      )
      draw_character_wrap_lines(buf, rest, content_x, index + 1)
    }
    _, _ -> Nil
  }
}

fn draw_character_wrap_cursor(
  buf: ffi.Buffer,
  text: String,
  eb: ffi.EditBuffer,
  content_x: Int,
  content_w: Int,
) -> Nil {
  let #(row, col) = edit_buffer.cursor(eb)
  let #(visual_row, visual_col) =
    model.char_wrap_cursor(text, row, col, content_w)
  let cx = content_x + visual_col
  let cy = editor_y + visual_row
  case cy < editor_y + editor_h && cx < content_x + content_w {
    True ->
      buffer.draw_text(
        buf,
        char_at_visual_cursor(text, row, col),
        cx,
        cy,
        editor_bg,
        cursor_bg,
        0,
      )
    False -> Nil
  }
}

fn char_at_visual_cursor(text: String, row: Int, col: Int) -> String {
  case line_at(string.split(text, "\n"), row) {
    Ok(line) ->
      case col < string.length(line) {
        True -> string.slice(line, col, 1)
        False -> " "
      }
    Error(_) -> " "
  }
}

fn next_wrap_mode_index(index: Int) -> Int {
  wrap_mode_from_index(index)
  |> model.cycle_wrap_mode
  |> wrap_mode_index
}

fn wrap_mode_from_index(index: Int) -> model.WrapMode {
  case index {
    0 -> model.WordWrap
    1 -> model.CharacterWrap
    _ -> model.NoWrap
  }
}

fn wrap_mode_index(mode: model.WrapMode) -> Int {
  case mode {
    model.WordWrap -> 0
    model.CharacterWrap -> 1
    model.NoWrap -> 2
  }
}

fn is_printable_text(raw: String) -> Bool {
  !string.starts_with(raw, "\u{1b}") && raw != "q"
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
  each_index_loop(0, n, f)
}

fn each_index_loop(i: Int, n: Int, f: fn(Int) -> Nil) -> Nil {
  case i < n {
    True -> {
      f(i)
      each_index_loop(i + 1, n, f)
    }
    False -> Nil
  }
}

fn line_at(lines: List(String), index: Int) -> Result(String, Nil) {
  case lines, index {
    [line, ..], 0 -> Ok(line)
    [_, ..rest], _ if index > 0 -> line_at(rest, index - 1)
    _, _ -> Error(Nil)
  }
}
