import opentui/examples/common
import opentui/examples/phase2_model as model
import opentui/examples/phase2_state as state
import opentui/examples/phase4_state as gstate
import opentui/interaction
import opentui/ui

pub fn main() -> Nil {
  let divider = state.create_int(32)
  let focus = gstate.create_generic(interaction.focus_group(2))

  common.run_interactive_ui_demo(
    "Split Mode Demo",
    "Split Mode Demo",
    fn(key) { handle_key(divider, focus, key) },
    fn() { view(divider, focus) },
  )
}

fn handle_key(
  divider: state.IntCell,
  focus: gstate.GenericCell,
  raw: String,
) -> Nil {
  let parsed = model.parse_key(raw)
  let fg: interaction.FocusGroup = gstate.get_generic(focus)

  case parsed {
    model.Tab -> gstate.set_generic(focus, interaction.focus_next(fg))
    model.ShiftTab -> gstate.set_generic(focus, interaction.focus_prev(fg))
    model.ArrowLeft | model.ArrowRight | model.Home | model.End ->
      state.set_int(
        divider,
        model.split_divider(state.get_int(divider), parsed),
      )
    _ -> Nil
  }
}

fn view(divider: state.IntCell, focus: gstate.GenericCell) -> List(ui.Element) {
  let left_width = state.get_int(divider)
  let right_x = 3 + left_width
  let right_width = 75 - left_width
  let fg: interaction.FocusGroup = gstate.get_generic(focus)

  [
    pane("Primary pane", 2, left_width, interaction.is_focused(fg, 0), [
      common.line("Tab switches active pane"),
      common.line("Left/Right resize split"),
      common.paragraph(
        "Focus switching now uses interaction.FocusGroup from opentui_ui with wrap-around navigation.",
      ),
    ]),
    pane("Secondary pane", right_x, right_width, interaction.is_focused(fg, 1), [
      common.line("Focused pane is highlighted"),
      common.line("Current divider is preserved"),
      common.paragraph(
        "The shared split reducer is frozen in tests. FocusGroup provides reusable focus management.",
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
