import gleam/int
import gleam/string
import opentui/edit_buffer
import opentui/examples/common
import opentui/examples/phase2_model as model
import opentui/ffi
import opentui/ui
import opentui/widgets

pub fn main() -> Nil {
  let input = edit_buffer.create(0)
  edit_buffer.set_text(input, "phase 2")

  common.run_interactive_ui_demo(
    "Input Demo",
    "Input Demo",
    fn(key) { handle_key(input, key) },
    fn() { view(input) },
  )
}

fn handle_key(input: ffi.EditBuffer, raw: String) -> Nil {
  case model.parse_key(raw) {
    model.ArrowLeft -> edit_buffer.move_left(input)
    model.ArrowRight -> edit_buffer.move_right(input)
    model.Backspace -> edit_buffer.delete_backward(input)
    model.Character(value) -> edit_buffer.insert_char(input, value)
    model.Space -> edit_buffer.insert_char(input, " ")
    _ -> Nil
  }
}

fn view(input: ffi.EditBuffer) -> List(ui.Element) {
  let value = edit_buffer.text(input)
  let #(_row, col) = edit_buffer.cursor(input)
  let display =
    widgets.InputState(value: value, cursor: col, focused: True)
    |> widgets.input_display_value

  [
    common.panel("Input field", 2, 3, 50, 18, [
      ui.Column([ui.Gap(1)], [
        common.line_with([ui.Attributes(1)], "Keyboard-first single-line input"),
        common.paragraph(
          "This Phase 2 demo keeps the interaction honest: characters, left and right arrows, and backspace are powered by the current edit buffer runtime wrapper.",
        ),
        ui.Spacer(1),
        common.line_with(
          [
            ui.Foreground(common.color(common.bg_color)),
            ui.Background(common.color(common.accent_blue)),
            ui.Attributes(1),
          ],
          "> " <> display,
        ),
        common.line("Cursor column: " <> int.to_string(col + 1)),
        common.line("Length: " <> int.to_string(string.length(value))),
      ]),
    ]),
    common.panel("Controls", 56, 3, 22, 18, [
      ui.Column([ui.Gap(1)], [
        common.line("Type to insert"),
        common.line("← → move cursor"),
        common.line("Backspace deletes"),
        ui.Spacer(1),
        common.paragraph(
          "Enter is intentionally ignored here so this example freezes the common single-line input behavior for later widgets.",
        ),
      ]),
    ]),
  ]
}
