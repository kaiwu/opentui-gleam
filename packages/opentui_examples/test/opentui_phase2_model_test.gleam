import gleam/string
import gleeunit/should
import opentui/examples/phase2_model as model

pub fn parse_key_classifies_common_sequences_test() {
  let _ = model.parse_key("\u{1b}[A") |> should.equal(model.ArrowUp)
  let _ = model.parse_key("\u{1b}[Z") |> should.equal(model.ShiftTab)
  let _ = model.parse_key("x") |> should.equal(model.Character("x"))
  model.parse_key("\u{1b}[200~")
  |> should.equal(model.Unknown("\u{1b}[200~"))
}

pub fn append_log_keeps_only_recent_lines_test() {
  model.append_log("one\ntwo", "three", 2)
  |> should.equal("two\nthree")
}

pub fn navigate_wraps_through_indices_test() {
  let _ = model.navigate(0, 4, model.ArrowUp) |> should.equal(3)
  let _ = model.navigate(3, 4, model.ArrowDown) |> should.equal(0)
  model.navigate(1, 4, model.End) |> should.equal(3)
}

pub fn navigate_available_skips_hidden_slots_test() {
  let availability = [True, False, True]

  let _ =
    model.navigate_available(0, availability, model.Tab) |> should.equal(2)
  let _ =
    model.navigate_available(2, availability, model.Tab) |> should.equal(0)
  model.navigate_available(1, availability, model.ShiftTab)
  |> should.equal(0)
}

pub fn slider_and_split_clamp_ranges_test() {
  let _ = model.adjust_slider(0, model.ArrowLeft) |> should.equal(0)
  let _ = model.adjust_slider(95, model.ArrowRight) |> should.equal(100)
  let _ = model.split_divider(18, model.ArrowLeft) |> should.equal(18)
  model.split_divider(54, model.ArrowRight) |> should.equal(54)
}

pub fn scroll_helpers_slice_visible_and_sticky_lines_test() {
  let lines = ["a", "b", "c", "d", "e"]
  let _ = model.visible_lines(lines, 2, 2) |> should.equal(["c", "d"])
  let #(sticky, body) = model.sticky_window(lines, 2, 1, 2)
  let _ = sticky |> should.equal(["a", "b"])
  let _ = body |> should.equal(["d", "e"])
  model.max_sticky_offset(12, 2, 6) |> should.equal(4)
}

pub fn restore_focus_and_markers_are_stable_test() {
  let availability = [True, False, True]
  let _ = model.restore_focus(1, availability) |> should.equal(2)
  let _ =
    model.navigate_available(2, [True, False, True], model.Tab)
    |> should.equal(0)
  let _ = model.selection_marker(1, 1, 1) |> should.equal("◉")
  let _ = model.focus_marker(0, 1) |> should.equal(" ")
  model.focus_marker(1, 1) |> should.equal("›")
}

pub fn key_label_mentions_named_keys_test() {
  model.key_label("\t")
  |> string.contains("Tab")
  |> should.equal(True)
}
