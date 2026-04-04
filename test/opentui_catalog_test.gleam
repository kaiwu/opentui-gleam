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
