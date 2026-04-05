import gleam/list
import opentui/examples/common
import opentui/examples/phase2_model as model
import opentui/examples/phase2_state as state
import opentui/ui

pub fn main() -> Nil {
  let focused = state.create_int(0)
  let hidden = state.create_bool(False)

  common.run_interactive_ui_demo(
    "Focus Restore Demo",
    "Focus Restore Demo",
    fn(key) { handle_key(focused, hidden, key) },
    fn() { view(focused, hidden) },
  )
}

fn handle_key(
  focused: state.IntCell,
  hidden: state.BoolCell,
  raw: String,
) -> Nil {
  let availability = visible_widgets(state.get_bool(hidden))
  let parsed = model.parse_key(raw)
  let current = state.get_int(focused)

  case parsed {
    model.Enter | model.Space ->
      case
        state.get_bool(hidden)
        || model.restore_focus(current, availability) == 1
      {
        True -> {
          let next_hidden = !state.get_bool(hidden)
          state.set_bool(hidden, next_hidden)
          state.set_int(focused, case next_hidden {
            True -> model.restore_focus(current, visible_widgets(next_hidden))
            False -> 1
          })
        }
        False -> Nil
      }
    _ ->
      state.set_int(
        focused,
        model.navigate_available(current, availability, parsed),
      )
  }
}

fn view(focused: state.IntCell, hidden: state.BoolCell) -> List(ui.Element) {
  let is_hidden = state.get_bool(hidden)
  let focus_index =
    model.restore_focus(state.get_int(focused), visible_widgets(is_hidden))

  [
    common.panel("Widgets", 2, 3, 38, 18, [
      ui.Column([ui.Gap(1)], widget_lines(focus_index, is_hidden)),
    ]),
    common.panel("Focus restore", 44, 3, 34, 18, [
      ui.Column([ui.Gap(1)], [
        common.line_with([ui.Attributes(1)], focus_label(focus_index)),
        common.line(
          "Details visible: "
          <> case is_hidden {
            True -> "no"
            False -> "yes"
          },
        ),
        ui.Spacer(1),
        common.paragraph(
          "Tab cycles only through visible widgets. Press Enter or Space on the Details row to hide it, then press Enter or Space again from any remaining widget to restore it with focus returned to Details.",
        ),
      ]),
    ]),
  ]
}

fn widget_lines(focused: Int, hidden: Bool) -> List(ui.Element) {
  [widget_line(0, focused, "Search field")]
  |> list.append(case hidden {
    True -> []
    False -> [widget_line(1, focused, "Details panel (toggle hide/show)")]
  })
  |> list.append([widget_line(2, focused, "Submit button")])
}

fn widget_line(index: Int, focused: Int, content: String) -> ui.Element {
  common.line_with(
    case index == focused {
      True -> [
        ui.Foreground(common.color(common.accent_blue)),
        ui.Attributes(1),
      ]
      False -> []
    },
    model.focus_marker(index, focused) <> " " <> content,
  )
}

fn visible_widgets(hidden: Bool) -> List(Bool) {
  [True, !hidden, True]
}

fn focus_label(index: Int) -> String {
  case index {
    0 -> "Current focus: Search field"
    1 -> "Current focus: Details panel"
    _ -> "Current focus: Submit button"
  }
}
