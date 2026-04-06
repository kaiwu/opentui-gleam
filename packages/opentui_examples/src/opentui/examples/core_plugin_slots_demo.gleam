import gleam/list
import opentui/examples/common
import opentui/examples/phase2_model
import opentui/examples/phase2_state as state
import opentui/examples/phase3_model as model
import opentui/ui

pub fn main() -> Nil {
  let focused = state.create_int(0)
  let header_on = state.create_bool(True)
  let sidebar_on = state.create_bool(True)
  let content_on = state.create_bool(True)
  let footer_on = state.create_bool(True)

  common.run_interactive_ui_demo(
    "Core Plugin Slots Demo",
    "Core Plugin Slots Demo",
    fn(key) {
      handle_key(focused, header_on, sidebar_on, content_on, footer_on, key)
    },
    fn() { view(focused, header_on, sidebar_on, content_on, footer_on) },
  )
}

fn handle_key(
  focused: state.IntCell,
  header_on: state.BoolCell,
  sidebar_on: state.BoolCell,
  content_on: state.BoolCell,
  footer_on: state.BoolCell,
  raw: String,
) -> Nil {
  let key = phase2_model.parse_key(raw)
  case key {
    phase2_model.ArrowUp | phase2_model.ArrowLeft ->
      state.set_int(focused, phase2_model.navigate(state.get_int(focused), 4, key))
    phase2_model.ArrowDown | phase2_model.ArrowRight ->
      state.set_int(focused, phase2_model.navigate(state.get_int(focused), 4, key))
    phase2_model.Enter | phase2_model.Space -> {
      let idx = state.get_int(focused)
      toggle_cell(idx, header_on, sidebar_on, content_on, footer_on)
    }
    _ -> Nil
  }
}

fn toggle_cell(
  idx: Int,
  header_on: state.BoolCell,
  sidebar_on: state.BoolCell,
  content_on: state.BoolCell,
  footer_on: state.BoolCell,
) -> Nil {
  case idx {
    0 -> state.set_bool(header_on, !state.get_bool(header_on))
    1 -> state.set_bool(sidebar_on, !state.get_bool(sidebar_on))
    2 -> state.set_bool(content_on, !state.get_bool(content_on))
    _ -> state.set_bool(footer_on, !state.get_bool(footer_on))
  }
}

fn view(
  focused: state.IntCell,
  header_on: state.BoolCell,
  sidebar_on: state.BoolCell,
  content_on: state.BoolCell,
  footer_on: state.BoolCell,
) -> List(ui.Element) {
  let foc = state.get_int(focused)
  let slots = [
    model.Slot("header", state.get_bool(header_on)),
    model.Slot("sidebar", state.get_bool(sidebar_on)),
    model.Slot("content", state.get_bool(content_on)),
    model.Slot("footer", state.get_bool(footer_on)),
  ]
  let active = model.active_slots(slots)

  [
    common.panel("Slot Registry", 2, 3, 30, 12, [
      ui.Column([ui.Gap(0)], slot_list(slots, foc, 0)),
    ]),
    common.panel("Composed Layout", 34, 3, 44, 12, [
      ui.Column([ui.Gap(0)], compose_layout(active)),
    ]),
    common.panel("Info", 2, 16, 76, 5, [
      ui.Column([ui.Gap(1)], [
        common.line(
          "Active: "
          <> active_label(active)
          <> "  ("
          <> count_label(list.length(active))
          <> "/4)",
        ),
        common.paragraph(
          "Higher-order slot composition: each slot maps to a render function. Toggle slots on/off to see the layout recompose. Pure data (Slot list) drives the view — no plugin runtime needed.",
        ),
      ]),
    ]),
  ]
}

fn slot_list(
  slots: List(model.Slot),
  focused: Int,
  index: Int,
) -> List(ui.Element) {
  case slots {
    [] -> []
    [slot, ..rest] -> {
      let marker = phase2_model.focus_marker(index, focused)
      let status = case slot.enabled {
        True -> "●"
        False -> "○"
      }
      let styles = case index == focused {
        True -> [
          ui.Foreground(common.color(common.accent_green)),
          ui.Attributes(1),
        ]
        False ->
          case slot.enabled {
            True -> [ui.Foreground(common.color(common.accent_blue))]
            False -> [ui.Foreground(common.color(common.muted_fg))]
          }
      }
      [
        common.line_with(styles, marker <> " " <> status <> " " <> slot.name),
        ..slot_list(rest, focused, index + 1)
      ]
    }
  }
}

fn compose_layout(active: List(model.Slot)) -> List(ui.Element) {
  case active {
    [] -> [
      common.line_with(
        [ui.Foreground(common.color(common.muted_fg))],
        "(all slots disabled)",
      ),
    ]
    _ -> list.map(active, render_slot)
  }
}

fn render_slot(slot: model.Slot) -> ui.Element {
  case slot.name {
    "header" ->
      common.line_with(
        [
          ui.Foreground(common.color(common.bg_color)),
          ui.Background(common.color(common.accent_blue)),
          ui.Attributes(1),
        ],
        " HEADER — OpenTUI Gleam                      ",
      )
    "sidebar" ->
      common.line_with(
        [ui.Foreground(common.color(common.accent_yellow))],
        "│ sidebar │ navigation · settings · help",
      )
    "content" ->
      common.line_with(
        [ui.Foreground(common.color(common.accent_green))],
        "│ content │ main application area",
      )
    "footer" ->
      common.line_with(
        [
          ui.Foreground(common.color(common.bg_color)),
          ui.Background(common.color(common.status_bg)),
        ],
        " FOOTER — status · version · q to quit        ",
      )
    _ ->
      common.line_with(
        [ui.Foreground(common.color(common.muted_fg))],
        "│ " <> slot.name <> " │ (unknown slot)",
      )
  }
}

fn active_label(active: List(model.Slot)) -> String {
  active
  |> model.slot_names
  |> join_names
}

fn join_names(names: List(String)) -> String {
  case names {
    [] -> "(none)"
    [name] -> name
    [name, ..rest] -> name <> ", " <> join_names(rest)
  }
}

fn count_label(n: Int) -> String {
  case n {
    0 -> "0"
    1 -> "1"
    2 -> "2"
    3 -> "3"
    _ -> "4"
  }
}
