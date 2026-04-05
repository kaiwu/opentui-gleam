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
