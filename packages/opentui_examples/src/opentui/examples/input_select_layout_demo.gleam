import gleam/string
import opentui/edit_buffer
import opentui/examples/common
import opentui/examples/phase2_model
import opentui/examples/phase2_state as state
import opentui/ffi
import opentui/ui

const options = ["Red", "Green", "Blue", "Yellow", "Purple"]

pub fn main() -> Nil {
  let focus_area = state.create_int(0)
  let selected = state.create_int(0)
  let focused_opt = state.create_int(0)
  let eb = edit_buffer.create(0)

  common.run_interactive_ui_demo(
    "Input Select Layout Demo",
    "Input Select Layout Demo",
    fn(key) { handle_key(focus_area, selected, focused_opt, eb, key) },
    fn() { view(focus_area, selected, focused_opt, eb) },
  )
}

fn handle_key(
  focus_area: state.IntCell,
  selected: state.IntCell,
  focused_opt: state.IntCell,
  eb: ffi.EditBuffer,
  raw: String,
) -> Nil {
  let key = phase2_model.parse_key(raw)
  case key {
    phase2_model.Tab ->
      state.set_int(focus_area, { state.get_int(focus_area) + 1 } % 2)
    phase2_model.ShiftTab ->
      state.set_int(focus_area, { state.get_int(focus_area) + 1 } % 2)
    _ ->
      case state.get_int(focus_area) {
        0 -> handle_input_key(eb, key, raw)
        _ -> handle_select_key(selected, focused_opt, key)
      }
  }
}

fn handle_input_key(
  eb: ffi.EditBuffer,
  key: phase2_model.Key,
  raw: String,
) -> Nil {
  case key {
    phase2_model.Backspace -> edit_buffer.delete_backward(eb)
    phase2_model.ArrowLeft -> edit_buffer.move_left(eb)
    phase2_model.ArrowRight -> edit_buffer.move_right(eb)
    phase2_model.Character(c) -> edit_buffer.insert_char(eb, c)
    _ -> {
      case string.length(raw) == 1 {
        True -> edit_buffer.insert_char(eb, raw)
        False -> Nil
      }
    }
  }
}

fn handle_select_key(
  selected: state.IntCell,
  focused_opt: state.IntCell,
  key: phase2_model.Key,
) -> Nil {
  let count = 5
  case key {
    phase2_model.Enter | phase2_model.Space ->
      state.set_int(selected, state.get_int(focused_opt))
    _ ->
      state.set_int(
        focused_opt,
        phase2_model.navigate(state.get_int(focused_opt), count, key),
      )
  }
}

fn view(
  focus_area: state.IntCell,
  selected: state.IntCell,
  focused_opt: state.IntCell,
  eb: ffi.EditBuffer,
) -> List(ui.Element) {
  let area = state.get_int(focus_area)
  let sel = state.get_int(selected)
  let foc = state.get_int(focused_opt)
  let text = edit_buffer.text(eb)
  let #(_row, col) = edit_buffer.cursor(eb)

  let input_border = case area {
    0 -> common.accent_blue
    _ -> common.border_fg
  }
  [
    common.panel_with_background("Input", 2, 3, 76, 5, common.panel_bg, [
      ui.Column([ui.Gap(0)], [
        ui.Box(
          [
            ui.Width(40),
            ui.Height(1),
            ui.Border("", common.color(input_border)),
          ],
          [],
        ),
        common.line(render_input(text, col, area == 0)),
      ]),
    ]),
    common.panel_with_background("Select Color", 2, 9, 38, 12, common.panel_bg, [
      ui.Column(
        [ui.Gap(0)],
        select_items(foc, sel, area == 1),
      ),
    ]),
    common.panel("Status", 42, 9, 36, 12, [
      ui.Column([ui.Gap(1)], [
        common.line("Focus: " <> focus_label(area)),
        common.line("Input: " <> text),
        common.line("Color: " <> nth_option(sel)),
        ui.Spacer(1),
        common.line("Tab    switch focus"),
        common.line("↑/↓    navigate select"),
        common.line("Enter  commit selection"),
        common.line("Type   edit input"),
      ]),
    ]),
  ]
}

fn render_input(text: String, col: Int, focused: Bool) -> String {
  case focused {
    True -> {
      let before = string.slice(text, 0, col)
      let after = string.slice(text, col, string.length(text) - col)
      before <> "█" <> after
    }
    False -> text
  }
}

fn select_items(
  focused: Int,
  selected: Int,
  active: Bool,
) -> List(ui.Element) {
  select_items_loop(options, 0, focused, selected, active)
}

fn select_items_loop(
  items: List(String),
  index: Int,
  focused: Int,
  selected: Int,
  active: Bool,
) -> List(ui.Element) {
  case items {
    [] -> []
    [item, ..rest] -> {
      let marker = phase2_model.selection_marker(index, focused, selected)
      let styles = case active && index == focused {
        True -> [
          ui.Foreground(common.color(common.accent_green)),
          ui.Attributes(1),
        ]
        False ->
          case index == selected {
            True -> [ui.Foreground(common.color(common.accent_blue))]
            False -> []
          }
      }
      [
        common.line_with(styles, " " <> marker <> " " <> item),
        ..select_items_loop(rest, index + 1, focused, selected, active)
      ]
    }
  }
}

fn focus_label(area: Int) -> String {
  case area {
    0 -> "Input"
    _ -> "Select"
  }
}

fn nth_option(index: Int) -> String {
  nth_or(options, index, "Red")
}

fn nth_or(items: List(String), index: Int, default: String) -> String {
  case items, index {
    [], _ -> default
    [item, ..], 0 -> item
    [_, ..rest], _ -> nth_or(rest, index - 1, default)
  }
}

