import gleam/int
import opentui/examples/common
import opentui/examples/phase2_model as model
import opentui/examples/phase2_state as state
import opentui/ui

pub fn main() -> Nil {
  let offset = state.create_int(0)

  common.run_interactive_ui_demo(
    "Scroll Example",
    "Scroll Example",
    fn(key) { handle_key(offset, key) },
    fn() { view(offset) },
  )
}

fn handle_key(offset: state.IntCell, raw: String) -> Nil {
  state.set_int(
    offset,
    model.adjust_scroll(
      state.get_int(offset),
      model.parse_key(raw),
      model.max_scroll_offset(16, 8),
    ),
  )
}

fn view(offset: state.IntCell) -> List(ui.Element) {
  let scroll = state.get_int(offset)

  [
    common.panel("Scrollable list", 2, 3, 48, 18, [
      ui.Column(
        [ui.Gap(1)],
        list_lines(model.visible_lines(entries(), scroll, 8)),
      ),
    ]),
    common.panel("Scroll state", 54, 3, 24, 18, [
      ui.Column([ui.Gap(1)], [
        common.line_with(
          [ui.Attributes(1)],
          "Offset: " <> int.to_string(scroll),
        ),
        common.line("Visible rows: 8"),
        common.line("Total rows: 16"),
        ui.Spacer(1),
        common.paragraph(
          "Up/Down, Home, and End are backed by a pure scroll reducer so later scroll widgets can inherit the same clamping rules.",
        ),
      ]),
    ]),
  ]
}

fn list_lines(lines: List(String)) -> List(ui.Element) {
  case lines {
    [] -> []
    [line, ..rest] -> [common.line(line), ..list_lines(rest)]
  }
}

fn entries() -> List(String) {
  [
    "01  renderer boot",
    "02  terminal setup",
    "03  event loop ready",
    "04  layout planned",
    "05  buffers cleared",
    "06  widgets mounted",
    "07  focus updated",
    "08  input committed",
    "09  selection changed",
    "10  slider adjusted",
    "11  scroll clamped",
    "12  sticky header kept",
    "13  split pane resized",
    "14  tests executed",
    "15  docs updated",
    "16  demo complete",
  ]
}
