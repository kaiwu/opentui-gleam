import opentui/examples/common
import opentui/examples/phase2_model as model
import opentui/examples/phase2_state as state
import opentui/ui

pub fn main() -> Nil {
  let divider = state.create_int(32)
  let focused = state.create_int(0)

  common.run_interactive_ui_demo(
    "Split Mode Demo",
    "Split Mode Demo",
    fn(key) { handle_key(divider, focused, key) },
    fn() { view(divider, focused) },
  )
}

fn handle_key(
  divider: state.IntCell,
  focused: state.IntCell,
  raw: String,
) -> Nil {
  let parsed = model.parse_key(raw)

  case parsed {
    model.Tab | model.ShiftTab ->
      state.set_int(focused, model.navigate(state.get_int(focused), 2, parsed))
    model.ArrowLeft | model.ArrowRight | model.Home | model.End ->
      state.set_int(
        divider,
        model.split_divider(state.get_int(divider), parsed),
      )
    _ -> Nil
  }
}

fn view(divider: state.IntCell, focused: state.IntCell) -> List(ui.Element) {
  let left_width = state.get_int(divider)
  let right_x = 3 + left_width
  let right_width = 75 - left_width
  let active = state.get_int(focused)

  [
    pane("Primary pane", 2, left_width, active == 0, [
      common.line("Tab switches active pane"),
      common.line("Left/Right resize split"),
      common.paragraph(
        "This is a manual multi-region layout built on the current buffer/ui stack while true split terminal modes are still pending in the runtime.",
      ),
    ]),
    pane("Secondary pane", right_x, right_width, active == 1, [
      common.line("Focused pane is highlighted"),
      common.line("Current divider is preserved"),
      common.paragraph(
        "The shared split reducer is now frozen in tests so future runtime-backed split modes can keep the same keyboard semantics.",
      ),
    ]),
  ]
}

fn pane(
  title: String,
  x: Int,
  width: Int,
  focused: Bool,
  children: List(ui.Element),
) -> ui.Element {
  common.panel_with_background(
    title,
    x,
    3,
    width,
    18,
    case focused {
      True -> common.accent_blue
      False -> common.panel_bg
    },
    [ui.Column([ui.Gap(1)], children)],
  )
}
