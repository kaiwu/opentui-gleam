import opentui/examples/common
import opentui/examples/phase2_model as model
import opentui/examples/phase2_state as state
import opentui/ui

pub fn main() -> Nil {
  let focused = state.create_int(0)
  let selected = state.create_int(0)

  common.run_interactive_ui_demo(
    "Select Demo",
    "Select Demo",
    fn(key) { handle_key(focused, selected, key) },
    fn() { view(focused, selected) },
  )
}

fn handle_key(
  focused: state.IntCell,
  selected: state.IntCell,
  raw: String,
) -> Nil {
  let parsed = model.parse_key(raw)
  let next_focus = model.navigate(state.get_int(focused), 4, parsed)
  state.set_int(focused, next_focus)

  case parsed {
    model.Enter | model.Space -> state.set_int(selected, next_focus)
    _ -> Nil
  }
}

fn view(focused: state.IntCell, selected: state.IntCell) -> List(ui.Element) {
  let focus_index = state.get_int(focused)
  let selected_index = state.get_int(selected)

  [
    common.panel("Options", 2, 3, 36, 18, [
      ui.Column(
        [ui.Gap(1)],
        option_elements(options(), 0, focus_index, selected_index),
      ),
    ]),
    common.panel("Selection", 42, 3, 36, 18, [
      ui.Column([ui.Gap(1)], [
        common.line_with([ui.Attributes(1)], "Selected item"),
        common.line_with(
          [ui.Foreground(common.color(common.accent_green))],
          option_at(selected_index),
        ),
        ui.Spacer(1),
        common.paragraph(
          "Use Up/Down or Tab to move focus. Press Enter or Space to commit the highlighted value.",
        ),
      ]),
    ]),
  ]
}

fn option_elements(
  entries: List(String),
  index: Int,
  focused: Int,
  selected: Int,
) -> List(ui.Element) {
  case entries {
    [] -> []
    [entry, ..rest] -> [
      common.line_with(
        option_styles(index, focused, selected),
        model.selection_marker(index, focused, selected) <> " " <> entry,
      ),
      ..option_elements(rest, index + 1, focused, selected)
    ]
  }
}

fn option_styles(index: Int, focused: Int, selected: Int) -> List(ui.Style) {
  case index == selected, index == focused {
    True, True -> [
      ui.Foreground(common.color(common.accent_green)),
      ui.Attributes(1),
    ]
    True, False -> [ui.Foreground(common.color(common.accent_green))]
    False, True -> [
      ui.Foreground(common.color(common.accent_blue)),
      ui.Attributes(1),
    ]
    False, False -> []
  }
}

fn options() -> List(String) {
  ["Gleam", "Runtime", "UI", "Examples"]
}

fn option_at(index: Int) -> String {
  case index {
    0 -> "Gleam"
    1 -> "Runtime"
    2 -> "UI"
    _ -> "Examples"
  }
}
