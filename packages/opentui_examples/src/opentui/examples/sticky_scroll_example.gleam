import gleam/int
import gleam/list
import opentui/examples/common
import opentui/examples/phase2_model as model
import opentui/examples/phase2_state as state
import opentui/ui

pub fn main() -> Nil {
  let offset = state.create_int(0)

  common.run_interactive_ui_demo(
    "Sticky Scroll Example",
    "Sticky Scroll Example",
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
      model.max_sticky_offset(12, 2, 6),
    ),
  )
}

fn view(offset: state.IntCell) -> List(ui.Element) {
  let scroll = state.get_int(offset)
  let #(sticky, body) = model.sticky_window(entries(), 2, scroll, 6)

  [
    common.panel("Sticky header", 2, 3, 48, 18, [
      ui.Column(
        [ui.Gap(1)],
        sticky_lines(sticky, True)
          |> list.append([ui.Spacer(1)])
          |> list.append(sticky_lines(body, False)),
      ),
    ]),
    common.panel("Semantics", 54, 3, 24, 18, [
      ui.Column([ui.Gap(1)], [
        common.line_with(
          [ui.Attributes(1)],
          "Offset: " <> int.to_string(scroll),
        ),
        common.line("Sticky rows: 2"),
        common.line("Body rows: 6"),
        ui.Spacer(1),
        common.paragraph(
          "The sticky window is pure data: the header rows stay fixed while the scroll offset only advances through the body lines.",
        ),
      ]),
    ]),
  ]
}

fn sticky_lines(lines: List(String), is_header: Bool) -> List(ui.Element) {
  case lines {
    [] -> []
    [line, ..rest] -> [
      common.line_with(
        case is_header {
          True -> [
            ui.Foreground(common.color(common.accent_yellow)),
            ui.Attributes(1),
          ]
          False -> []
        },
        line,
      ),
      ..sticky_lines(rest, is_header)
    ]
  }
}

fn entries() -> List(String) {
  [
    "Section: Phase 2 demos",
    "Columns: title | state | notes",
    "row 01  keyboard events",
    "row 02  focus reducers",
    "row 03  selection state",
    "row 04  slider values",
    "row 05  list scrolling",
    "row 06  sticky rows",
    "row 07  split panes",
    "row 08  runtime gaps",
    "row 09  tests",
    "row 10  verification",
  ]
}
