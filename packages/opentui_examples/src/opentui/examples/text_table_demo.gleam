import gleam/list
import opentui/examples/common
import opentui/examples/phase2_model
import opentui/examples/phase2_state as state
import opentui/examples/phase3_model as model
import opentui/ui

pub fn main() -> Nil {
  let align_mode = state.create_int(0)

  common.run_interactive_ui_demo(
    "Text Table Demo",
    "Text Table Demo",
    fn(key) {
      let k = phase2_model.parse_key(key)
      state.set_int(
        align_mode,
        phase2_model.navigate(state.get_int(align_mode), 4, k),
      )
    },
    fn() { view(align_mode) },
  )
}

fn view(align_mode: state.IntCell) -> List(ui.Element) {
  let mode = state.get_int(align_mode)
  let aligns = alignments_for(mode)
  let lines = model.format_table(headers(), rows(), aligns)

  [
    common.panel("Table", 2, 3, 54, 18, [
      ui.Column([ui.Gap(0)], list.map(lines, common.line)),
    ]),
    common.panel("Settings", 58, 3, 20, 18, [
      ui.Column([ui.Gap(1)], [
        common.line("Alignment:"),
        mode_line(0, mode, "All left"),
        mode_line(1, mode, "Mixed"),
        mode_line(2, mode, "All right"),
        mode_line(3, mode, "All center"),
        ui.Spacer(1),
        common.line("←/→ or Tab"),
        common.line("to cycle"),
        ui.Spacer(1),
        common.paragraph(
          "Pure table formatting — headers, rows, and alignments as data transformed into text lines.",
        ),
      ]),
    ]),
  ]
}

fn mode_line(index: Int, current: Int, label: String) -> ui.Element {
  let marker = case index == current {
    True -> "› "
    False -> "  "
  }
  let styles = case index == current {
    True -> [
      ui.Foreground(common.color(common.accent_green)),
      ui.Attributes(1),
    ]
    False -> []
  }
  common.line_with(styles, marker <> label)
}

fn alignments_for(mode: Int) -> List(model.Alignment) {
  case mode {
    0 -> [model.AlignLeft, model.AlignLeft, model.AlignLeft, model.AlignLeft]
    1 -> [model.AlignLeft, model.AlignLeft, model.AlignRight, model.AlignCenter]
    2 -> [
      model.AlignRight, model.AlignRight, model.AlignRight, model.AlignRight,
    ]
    _ -> [
      model.AlignCenter, model.AlignCenter, model.AlignCenter,
      model.AlignCenter,
    ]
  }
}

fn headers() -> List(String) {
  ["Name", "Lang", "Stars", "Status"]
}

fn rows() -> List(List(String)) {
  [
    ["gleam", "Gleam", "5.2k", "active"],
    ["opentui", "Zig/TS", "1.8k", "active"],
    ["lustre", "Gleam", "2.1k", "active"],
    ["wisp", "Gleam", "890", "stable"],
    ["birdie", "Gleam", "340", "new"],
  ]
}
