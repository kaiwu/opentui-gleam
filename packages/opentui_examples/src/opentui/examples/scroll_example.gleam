import gleam/int
import gleam/list
import opentui/examples/common
import opentui/examples/phase2_model as model
import opentui/examples/phase4_state as state
import opentui/ui
import opentui/widgets

pub fn main() -> Nil {
  let ss = state.create_generic(widgets.scroll_state(8)
    |> widgets.set_content_height(16))

  common.run_interactive_ui_demo(
    "Scroll Example",
    "Scroll Example",
    fn(key) { handle_key(ss, key) },
    fn() { view(ss) },
  )
}

fn handle_key(ss: state.GenericCell, raw: String) -> Nil {
  let s: widgets.ScrollState = state.get_generic(ss)
  let new_s = case model.parse_key(raw) {
    model.ArrowUp -> widgets.scroll_up(s, 1)
    model.ArrowDown -> widgets.scroll_down(s, 1)
    model.Home -> widgets.scroll_to(s, 0)
    model.End -> widgets.scroll_to(s, s.content_height)
    _ -> s
  }
  state.set_generic(ss, new_s)
}

fn view(ss: state.GenericCell) -> List(ui.Element) {
  let s: widgets.ScrollState = state.get_generic(ss)

  let rows = list.map(entries(), common.line)

  [
    common.panel("Scrollable list", 2, 3, 48, 18, [
      widgets.scroll_view([ui.Gap(1)], s, rows),
    ]),
    common.panel("Scroll state", 54, 3, 24, 18, [
      ui.Column([ui.Gap(1)], [
        common.line_with(
          [ui.Attributes(1)],
          "Offset: " <> int.to_string(s.offset),
        ),
        common.line("Visible rows: 8"),
        common.line("Total rows: 16"),
        ui.Spacer(1),
        common.paragraph(
          "Now backed by widgets.ScrollState from opentui_ui. Up/Down scroll, Home/End jump to bounds.",
        ),
      ]),
    ]),
  ]
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
