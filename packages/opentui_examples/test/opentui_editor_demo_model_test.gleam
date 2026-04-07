import gleeunit/should
import opentui/examples/editor_demo_model as model

pub fn cycle_wrap_mode_cycles_all_states_test() {
  let _ =
    model.cycle_wrap_mode(model.WordWrap) |> should.equal(model.CharacterWrap)
  let _ =
    model.cycle_wrap_mode(model.CharacterWrap) |> should.equal(model.NoWrap)
  model.cycle_wrap_mode(model.NoWrap) |> should.equal(model.WordWrap)
}

pub fn line_number_rows_adds_blank_continuations_test() {
  let rows = model.line_number_rows("abcdef\nghi", 3, model.CharacterWrap)
  rows |> should.equal(["1", "", "2"])
}

pub fn status_text_includes_editor_flags_test() {
  let status = model.status_text(2, 4, model.WordWrap, True, True, False)
  let _ =
    status
    |> should.equal(
      "Ln 3, Col 5 | Wrap: word | Lines: on | Undo: on | Redo: off",
    )
}

pub fn char_wrap_cursor_accounts_for_prior_wrapped_rows_test() {
  model.char_wrap_cursor("abcdef\nghi", 1, 2, 3) |> should.equal(#(2, 2))
}
