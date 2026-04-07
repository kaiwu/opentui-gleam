import gleeunit/should
import opentui/buffer
import opentui/edit_buffer
import opentui/editor_view
import opentui/types

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
