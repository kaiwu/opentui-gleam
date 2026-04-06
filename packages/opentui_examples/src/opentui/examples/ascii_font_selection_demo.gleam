import gleam/list
import opentui/examples/common
import opentui/examples/phase2_model
import opentui/examples/phase2_state as state
import opentui/examples/phase3_model as model
import opentui/ui

const words = ["GLEAM", "HI", "FP", "TUI", "ZIG"]

pub fn main() -> Nil {
  let word_index = state.create_int(0)

  common.run_interactive_ui_demo(
    "ASCII Font Selection Demo",
    "ASCII Font Selection Demo",
    fn(key) {
      let k = phase2_model.parse_key(key)
      state.set_int(
        word_index,
        phase2_model.navigate(state.get_int(word_index), 5, k),
      )
    },
    fn() { view(word_index) },
  )
}

fn view(word_index: state.IntCell) -> List(ui.Element) {
  let idx = state.get_int(word_index)
  let word = nth_word(idx)
  let banner_lines = model.ascii_banner(word)

  [
    common.panel("ASCII Banner", 2, 3, 76, 10, [
      ui.Column(
        [ui.Gap(0)],
        list.map(banner_lines, fn(line) {
          common.line_with(
            [
              ui.Foreground(common.color(common.accent_green)),
              ui.Attributes(1),
            ],
            line,
          )
        }),
      ),
    ]),
    common.panel("Controls", 2, 14, 38, 7, [
      ui.Column([ui.Gap(1)], [
        common.line("Current: " <> word),
        common.line("←/→ or Tab to cycle"),
        common.line("Home/End for first/last"),
      ]),
    ]),
    common.panel("Words", 42, 14, 36, 7, [
      ui.Column([ui.Gap(0)], word_list(idx)),
    ]),
  ]
}

fn word_list(current: Int) -> List(ui.Element) {
  word_list_items(words, 0, current)
}

fn word_list_items(
  items: List(String),
  index: Int,
  current: Int,
) -> List(ui.Element) {
  case items {
    [] -> []
    [word, ..rest] -> {
      let marker = phase2_model.focus_marker(index, current)
      let styles = case index == current {
        True -> [
          ui.Foreground(common.color(common.accent_blue)),
          ui.Attributes(1),
        ]
        False -> []
      }
      [
        common.line_with(styles, marker <> " " <> word),
        ..word_list_items(rest, index + 1, current)
      ]
    }
  }
}

fn nth_word(index: Int) -> String {
  nth_or(words, index, "GLEAM")
}

fn nth_or(items: List(String), index: Int, default: String) -> String {
  case items, index {
    [], _ -> default
    [item, ..], 0 -> item
    [_, ..rest], _ -> nth_or(rest, index - 1, default)
  }
}
