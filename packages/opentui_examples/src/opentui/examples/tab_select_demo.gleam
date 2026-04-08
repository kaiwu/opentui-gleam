import opentui/examples/common
import opentui/examples/phase2_model as model
import opentui/examples/phase4_state as state
import opentui/ui
import opentui/widgets

const tab_labels = ["Overview", "Runtime", "Tests"]

pub fn main() -> Nil {
  let tabs = state.create_generic(widgets.tab_state(3))

  common.run_interactive_ui_demo(
    "Tab Select Demo",
    "Tab Select Demo",
    fn(key) { handle_key(tabs, key) },
    fn() { view(tabs) },
  )
}

fn handle_key(tabs: state.GenericCell, raw: String) -> Nil {
  let t: widgets.TabState = state.get_generic(tabs)
  let new_t = case model.parse_key(raw) {
    model.ArrowRight | model.Tab -> widgets.tab_next(t)
    model.ArrowLeft | model.ShiftTab -> widgets.tab_prev(t)
    model.ArrowDown | model.ArrowUp -> t
    _ -> t
  }
  state.set_generic(tabs, new_t)
}

fn view(tabs: state.GenericCell) -> List(ui.Element) {
  let t: widgets.TabState = state.get_generic(tabs)

  [
    common.panel("Tabs", 2, 3, 76, 6, [
      ui.Column([ui.Gap(1)], [
        widgets.tab_bar(
          [],
          t,
          tab_labels,
          [ui.Foreground(common.color(common.muted_fg))],
          [
            ui.Foreground(common.color(common.accent_blue)),
            ui.Attributes(1),
          ],
        ),
        common.line("Use Left/Right or Tab/Shift+Tab to switch tabs."),
      ]),
    ]),
    common.panel(active_title(t.active), 2, 11, 76, 10, [
      ui.Column([ui.Gap(1)], active_body(t.active)),
    ]),
  ]
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
        "Now backed by widgets.TabState from opentui_ui. Tab switching uses tab_next/tab_prev with wrapping navigation.",
      ),
    ]
    1 -> [
      common.line("Current stack"),
      common.line("- widgets.TabState"),
      common.line("- widgets.tab_bar renderer"),
      common.line("- declarative render pass"),
    ]
    _ -> [
      common.line("Testability"),
      common.paragraph(
        "The tab state transitions are pure widgets.TabState functions, fully covered by opentui_ui tests.",
      ),
    ]
  }
}
