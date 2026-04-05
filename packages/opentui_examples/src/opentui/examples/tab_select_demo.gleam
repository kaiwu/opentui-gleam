import opentui/examples/common
import opentui/examples/phase2_model as model
import opentui/examples/phase2_state as state
import opentui/ui

pub fn main() -> Nil {
  let active = state.create_int(0)

  common.run_interactive_ui_demo(
    "Tab Select Demo",
    "Tab Select Demo",
    fn(key) { handle_key(active, key) },
    fn() { view(active) },
  )
}

fn handle_key(active: state.IntCell, raw: String) -> Nil {
  state.set_int(
    active,
    model.navigate(state.get_int(active), 3, model.parse_key(raw)),
  )
}

fn view(active: state.IntCell) -> List(ui.Element) {
  let index = state.get_int(active)

  [
    common.panel("Tabs", 2, 3, 76, 6, [
      ui.Column([ui.Gap(1)], [
        common.line_with([ui.Attributes(1)], tab_strip(index)),
        common.line("Use Left/Right or Tab/Shift+Tab to switch tabs."),
      ]),
    ]),
    common.panel(active_title(index), 2, 11, 76, 10, [
      ui.Column([ui.Gap(1)], active_body(index)),
    ]),
  ]
}

fn tab_strip(active: Int) -> String {
  case active {
    0 -> "[ Overview ]   Runtime   Tests"
    1 -> "Overview   [ Runtime ]   Tests"
    _ -> "Overview   Runtime   [ Tests ]"
  }
}

fn active_title(active: Int) -> String {
  case active {
    0 -> "Overview"
    1 -> "Runtime"
    _ -> "Tests"
  }
}

fn active_body(active: Int) -> List(ui.Element) {
  case active {
    0 -> [
      common.line("Keyboard-first tab state"),
      common.paragraph(
        "This view freezes the common active-tab navigation semantics without pretending focus restoration or mouse activation already exist.",
      ),
    ]
    1 -> [
      common.line("Current stack"),
      common.line("- raw key strings"),
      common.line("- pure tab reducer"),
      common.line("- declarative render pass"),
    ]
    _ -> [
      common.line("Testability"),
      common.paragraph(
        "The tab state transitions are pure and covered in the Phase 2 model tests, so later widget extraction can keep the same behavior.",
      ),
    ]
  }
}
