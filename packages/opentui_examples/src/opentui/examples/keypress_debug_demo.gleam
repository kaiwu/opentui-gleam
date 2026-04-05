import opentui/edit_buffer
import opentui/examples/common
import opentui/examples/phase2_model as model
import opentui/ffi
import opentui/renderer
import opentui/ui

const intro = "Press keys to inspect the current keyboard stream. Arrow keys, Tab, Shift+Tab, Home, End, and regular characters are labeled below."

pub fn main() -> Nil {
  let log = edit_buffer.create(0)
  edit_buffer.set_text(log, intro)

  common.run_interactive_ui_demo_with_setup(
    "Keypress Debug Demo",
    "Keypress Debug Demo",
    fn(r) { renderer.enable_kitty_keyboard(r, 1) },
    fn(key) { handle_key(log, key) },
    fn() { view(log) },
  )
}

fn handle_key(log: ffi.EditBuffer, raw: String) -> Nil {
  edit_buffer.set_text(
    log,
    model.append_log(edit_buffer.text(log), model.key_label(raw), 10),
  )
}

fn view(log: ffi.EditBuffer) -> List(ui.Element) {
  [
    common.panel("Observed keys", 2, 3, 50, 18, [
      ui.Column([ui.Gap(1)], [
        common.line_with([ui.Attributes(1)], "Raw input labels"),
        common.paragraph_with([ui.MaxLines(12)], edit_buffer.text(log)),
      ]),
    ]),
    common.panel("Notes", 56, 3, 22, 18, [
      ui.Column([ui.Gap(1)], [
        common.line("Kitty keyboard: on"),
        common.line("q still quits loop"),
        ui.Spacer(1),
        common.paragraph(
          "This keeps the raw keyboard stream visible even now that typed runtime input events exist, which makes it useful for verifying terminal sequences and future parser changes.",
        ),
      ]),
    ]),
  ]
}
