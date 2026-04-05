import gleam/int
import opentui/examples/common
import opentui/examples/phase2_model as model
import opentui/examples/phase2_state as state
import opentui/ui

pub fn main() -> Nil {
  let value = state.create_int(40)

  common.run_interactive_ui_demo(
    "Slider Demo",
    "Slider Demo",
    fn(key) { handle_key(value, key) },
    fn() { view(value) },
  )
}

fn handle_key(value: state.IntCell, raw: String) -> Nil {
  state.set_int(
    value,
    model.adjust_slider(state.get_int(value), model.parse_key(raw)),
  )
}

fn view(value: state.IntCell) -> List(ui.Element) {
  let current = state.get_int(value)

  [
    common.panel("Slider", 2, 3, 76, 18, [
      ui.Column([ui.Gap(1)], [
        common.line_with([ui.Attributes(1)], "Keyboard-controlled slider"),
        common.line_with(
          [
            ui.Foreground(common.color(common.bg_color)),
            ui.Background(common.color(common.accent_yellow)),
            ui.Attributes(1),
          ],
          "["
            <> model.slider_bar(current, 32)
            <> "] "
            <> int.to_string(current)
            <> "%",
        ),
        common.line("Left/Right adjust by 5"),
        common.line("Home -> 0, End -> 100"),
        ui.Spacer(1),
        common.paragraph(
          "Mouse dragging is still blocked by missing event parsing in the runtime, but the common slider value semantics are now implemented and tested.",
        ),
      ]),
    ]),
  ]
}
