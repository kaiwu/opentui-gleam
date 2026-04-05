import gleam/string
import gleeunit/should
import opentui/catalog

pub fn catalog_lists_editor_demo_test() {
  catalog.help_text()
  |> string.contains("opentui/examples/editor")
  |> should.equal(True)
}

pub fn catalog_registers_editor_demo_test() {
  case catalog.demos() {
    [catalog.Demo(id:, module:, description:), ..] -> {
      let _ = id |> should.equal("editor")
      let _ = module |> should.equal("opentui/examples/editor")
      let has_description = string.length(description) > 0
      let _ = has_description |> should.equal(True)
      Nil
    }
    [] -> panic as "expected at least one demo in the catalog"
  }
}

pub fn catalog_lists_new_demo_modules_test() {
  let help = catalog.help_text()
  help
  |> string.contains("opentui/examples/terminal_title")
  |> should.equal(True)
  help |> string.contains("opentui/examples/text_wrap") |> should.equal(True)
  help
  |> string.contains("opentui/examples/text_truncation")
  |> should.equal(True)
}

pub fn catalog_lists_stub_demo_modules_test() {
  let help = catalog.help_text()
  help
  |> string.contains("opentui/examples/text_selection_demo")
  |> should.equal(True)
  help
  |> string.contains("[stub] planned in Phase 3")
  |> should.equal(True)
}

pub fn catalog_has_no_phase_1_stubs_test() {
  let help = catalog.help_text()
  help
  |> string.contains("[stub] planned in Phase 1")
  |> should.equal(False)
}

pub fn catalog_marks_keyboard_phase_2_demos_done_test() {
  let help = catalog.help_text()
  let _ =
    help |> string.contains("opentui/examples/input_demo") |> should.equal(True)
  let _ =
    help
    |> string.contains("opentui/examples/select_demo")
    |> should.equal(True)
  let _ =
    help
    |> string.contains("opentui/examples/keypress_debug_demo")
    |> should.equal(True)
  help
  |> string.contains(
    "[done] Implemented keyboard stream inspection using the current editor loop.",
  )
  |> should.equal(True)
}

pub fn catalog_keeps_mouse_phase_2_demos_stubbed_test() {
  let help = catalog.help_text()
  let _ =
    help
    |> string.contains("opentui/examples/mouse_interaction_demo")
    |> should.equal(True)
  let _ =
    help
    |> string.contains("opentui/examples/scrollbox_mouse_test")
    |> should.equal(True)
  help
  |> string.contains(
    "[done] Implemented mouse-wheel scrolling and row hit-testing over a rebuilt hit grid.",
  )
  |> should.equal(True)
}

pub fn catalog_has_no_phase_2_stubs_test() {
  catalog.help_text()
  |> string.contains("[stub] planned in Phase 2")
  |> should.equal(False)
}
