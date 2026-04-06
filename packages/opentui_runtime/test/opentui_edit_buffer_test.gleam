import gleeunit/should
import opentui/edit_buffer

pub fn edit_buffer_supports_insert_delete_and_history_test() {
  let buffer = edit_buffer.create(0)

  edit_buffer.set_text(buffer, "ab")
  edit_buffer.move_left(buffer)
  edit_buffer.delete_forward(buffer)
  let _ = edit_buffer.text(buffer) |> should.equal("b")
  let _ = edit_buffer.can_undo(buffer) |> should.equal(True)

  edit_buffer.undo(buffer)
  let _ = edit_buffer.text(buffer) |> should.equal("ab")
  let _ = edit_buffer.can_redo(buffer) |> should.equal(True)

  edit_buffer.redo(buffer)
  let _ = edit_buffer.text(buffer) |> should.equal("b")

  edit_buffer.insert_text(buffer, "z")
  edit_buffer.text(buffer) |> should.equal("zb")
}

pub fn multiline_cursor_navigation_test() {
  let buffer = edit_buffer.create(0)
  edit_buffer.set_text(buffer, "first")
  edit_buffer.new_line(buffer)
  edit_buffer.insert_text(buffer, "second")

  let #(row, _col) = edit_buffer.cursor(buffer)
  let _ = row |> should.equal(1)

  edit_buffer.move_up(buffer)
  let #(row2, _col2) = edit_buffer.cursor(buffer)
  row2 |> should.equal(0)
}

pub fn insert_char_and_backspace_test() {
  let buffer = edit_buffer.create(0)
  edit_buffer.insert_char(buffer, "a")
  edit_buffer.insert_char(buffer, "b")
  edit_buffer.insert_char(buffer, "c")
  let _ = edit_buffer.text(buffer) |> should.equal("abc")

  edit_buffer.delete_backward(buffer)
  edit_buffer.text(buffer) |> should.equal("ab")
}

pub fn cursor_left_right_test() {
  let buffer = edit_buffer.create(0)
  edit_buffer.set_text(buffer, "xy")

  // cursor starts at 0 after set_text — move right into the middle
  edit_buffer.move_right(buffer)
  edit_buffer.insert_char(buffer, "z")
  edit_buffer.text(buffer) |> should.equal("xzy")
}

pub fn fresh_buffer_has_no_history_test() {
  let buffer = edit_buffer.create(0)
  let _ = edit_buffer.can_undo(buffer) |> should.equal(False)
  edit_buffer.can_redo(buffer) |> should.equal(False)
}
