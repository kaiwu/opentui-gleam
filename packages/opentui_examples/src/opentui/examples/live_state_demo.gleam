import gleam/int
import opentui/examples/common
import opentui/examples/phase2_model
import opentui/examples/phase2_state as state
import opentui/ui

pub fn main() -> Nil {
  let counter = state.create_int(0)
  let toggle = state.create_bool(False)
  let slider = state.create_int(50)
  let active_tab = state.create_int(0)

  common.run_interactive_ui_demo(
    "Live State Demo",
    "Live State Demo",
    fn(key) { handle_key(counter, toggle, slider, active_tab, key) },
    fn() { view(counter, toggle, slider, active_tab) },
  )
}

fn handle_key(
  counter: state.IntCell,
  toggle: state.BoolCell,
  slider: state.IntCell,
  active_tab: state.IntCell,
  raw: String,
) -> Nil {
  let key = phase2_model.parse_key(raw)
  case key {
    phase2_model.Character("+") ->
      state.set_int(counter, state.get_int(counter) + 1)
    phase2_model.Character("-") ->
      state.set_int(counter, phase2_model.clamp(state.get_int(counter) - 1, 0, 99))
    phase2_model.Character("t") ->
      state.set_bool(toggle, !state.get_bool(toggle))
    phase2_model.ArrowLeft ->
      state.set_int(slider, phase2_model.adjust_slider(state.get_int(slider), phase2_model.ArrowLeft))
    phase2_model.ArrowRight ->
      state.set_int(slider, phase2_model.adjust_slider(state.get_int(slider), phase2_model.ArrowRight))
    phase2_model.Tab ->
      state.set_int(active_tab, { state.get_int(active_tab) + 1 } % 3)
    _ -> Nil
  }
}

fn view(
  counter: state.IntCell,
  toggle: state.BoolCell,
  slider: state.IntCell,
  active_tab: state.IntCell,
) -> List(ui.Element) {
  let c = state.get_int(counter)
  let t = state.get_bool(toggle)
  let s = state.get_int(slider)
  let tab = state.get_int(active_tab)

  [
    common.panel("Counter", 2, 3, 38, 5, [
      ui.Column([ui.Gap(0)], [
        common.line_with(
          [ui.Foreground(common.color(common.accent_blue)), ui.Attributes(1)],
          "Value: " <> int.to_string(c),
        ),
        common.line(counter_bar(c, 30)),
      ]),
    ]),
    common.panel("Toggle", 42, 3, 36, 5, [
      ui.Column([ui.Gap(0)], [
        common.line_with(
          [
            ui.Foreground(common.color(case t {
              True -> common.accent_green
              False -> common.accent_pink
            })),
            ui.Attributes(1),
          ],
          case t {
            True -> "● ON"
            False -> "○ OFF"
          },
        ),
        common.line("Press 't' to toggle"),
      ]),
    ]),
    common.panel("Slider", 2, 9, 38, 5, [
      ui.Column([ui.Gap(0)], [
        common.line_with(
          [ui.Foreground(common.color(common.accent_orange)), ui.Attributes(1)],
          phase2_model.slider_bar(s, 30) <> " " <> int.to_string(s) <> "%",
        ),
        common.line("←/→ to adjust"),
      ]),
    ]),
    common.panel("Tabs", 42, 9, 36, 5, [
      ui.Column([ui.Gap(0)], [
        common.line(tab_header(tab)),
        common.line("Tab to cycle  ·  content: " <> tab_content(tab)),
      ]),
    ]),
    common.panel("Architecture", 2, 15, 76, 6, [
      ui.Column([ui.Gap(1)], [
        common.paragraph(
          "Four independent state cells (IntCell, BoolCell) drive four UI quadrants. All rendering is pure functions of cell values — no reconciler, no subscriptions, no diff. The event loop reads cells, calls view(), renders the element tree.",
        ),
        common.line_with(
          [ui.Foreground(common.color(common.muted_fg))],
          "+/- counter  ·  t toggle  ·  ←/→ slider  ·  Tab tabs",
        ),
      ]),
    ]),
  ]
}

fn counter_bar(value: Int, width: Int) -> String {
  let filled = phase2_model.clamp(value * width / 20, 0, width)
  repeat("█", filled) <> repeat("░", width - filled)
}

fn tab_header(active: Int) -> String {
  tab_label(0, active, "Overview")
  <> "  "
  <> tab_label(1, active, "Runtime")
  <> "  "
  <> tab_label(2, active, "Tests")
}

fn tab_label(index: Int, active: Int, name: String) -> String {
  case index == active {
    True -> "[ " <> name <> " ]"
    False -> "  " <> name <> "  "
  }
}

fn tab_content(active: Int) -> String {
  case active {
    0 -> "dashboard"
    1 -> "renderer"
    _ -> "passing"
  }
}

fn repeat(s: String, n: Int) -> String {
  case n <= 0 {
    True -> ""
    False -> s <> repeat(s, n - 1)
  }
}
