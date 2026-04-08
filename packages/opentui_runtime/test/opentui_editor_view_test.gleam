import gleeunit/should
import opentui/buffer
import opentui/edit_buffer
import opentui/editor_view
import opentui/types

pub fn line_count_empty_test() {
  editor_view.line_count("") |> should.equal(1)
}

pub fn line_count_single_line_test() {
  editor_view.line_count("hello") |> should.equal(1)
}

pub fn line_count_multiple_lines_test() {
  editor_view.line_count("one\ntwo\nthree") |> should.equal(3)
}

pub fn line_count_trailing_newline_test() {
  editor_view.line_count("a\nb\n") |> should.equal(3)
}

pub fn gutter_width_small_test() {
  editor_view.gutter_width(5) |> should.equal(2)
}

pub fn gutter_width_medium_test() {
  editor_view.gutter_width(100) |> should.equal(3)
}

pub fn gutter_width_large_test() {
  editor_view.gutter_width(1000) |> should.equal(4)
}

pub fn cursor_scroll_state_cursor_visible_test() {
  let eb = edit_buffer.create(0)
  edit_buffer.set_text(eb, "line1\nline2\nline3")
  // Cursor starts at row 0, scroll 0, viewport 10 — no scroll needed
  let #(_row, _col, scroll) = editor_view.cursor_scroll_state(eb, 10, 0)
  scroll |> should.equal(0)
}

pub fn cursor_scroll_state_cursor_above_test() {
  let eb = edit_buffer.create(0)
  edit_buffer.set_text(eb, "line1\nline2\nline3")
  // Cursor at row 0, but scroll is at 2 — should scroll up to row 0
  let #(_row, _col, scroll) = editor_view.cursor_scroll_state(eb, 5, 2)
  scroll |> should.equal(0)
}

pub fn render_smoke_test() {
  let edit = edit_buffer.create(0)
  edit_buffer.set_text(edit, "hello\nworld")
  let view = editor_view.create(edit, 10, 5)

  let ok = case buffer.create(16, 8, False, types.Normal, "render-test") {
    Ok(buf) -> {
      editor_view.render(buf, view, 0, 0, 10, 5, False)
      buffer.destroy(buf)
      True
    }
    Error(_) -> False
  }

  editor_view.destroy(view)
  ok |> should.equal(True)
}

pub fn editor_view_draws_with_viewport_smoke_test() {
  let edit = edit_buffer.create(0)
  edit_buffer.set_text(edit, "one\ntwo\nthree\nfour")

  let view = editor_view.create(edit, 12, 2)
  editor_view.set_viewport(view, 0, 1, 12, 2, False)

  let draw_ok = case
    buffer.create(16, 4, False, types.Normal, "editor-view-test")
  {
    Ok(buf) -> {
      editor_view.draw_to(buf, view, 0, 0)
      buffer.destroy(buf)
      True
    }
    Error(_) -> False
  }

  editor_view.destroy(view)
  draw_ok |> should.equal(True)
}

pub fn editor_view_draws_wrapped_smoke_test() {
  let edit = edit_buffer.create(0)
  edit_buffer.set_text(edit, "alpha beta gamma delta")

  let view = editor_view.create(edit, 8, 3)
  editor_view.set_viewport(view, 0, 0, 8, 3, True)

  let draw_ok = case
    buffer.create(16, 4, False, types.Normal, "editor-view-wrap-test")
  {
    Ok(buf) -> {
      editor_view.draw_to(buf, view, 0, 0)
      buffer.destroy(buf)
      True
    }
    Error(_) -> False
  }

  editor_view.destroy(view)
  draw_ok |> should.equal(True)
}
