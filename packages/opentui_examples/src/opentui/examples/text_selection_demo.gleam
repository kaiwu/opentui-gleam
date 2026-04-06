import gleam/int
import gleam/list
import gleam/string
import opentui/examples/common
import opentui/examples/phase2_model
import opentui/examples/phase2_state as state
import opentui/examples/phase3_model as model
import opentui/ui

const sample_text = "The quick brown fox jumps over the lazy dog. Gleam makes TUI composition safe."

pub fn main() -> Nil {
  let cursor = state.create_int(0)
  let anchor = state.create_int(0)

  common.run_interactive_ui_demo(
    "Text Selection Demo",
    "Text Selection Demo",
    fn(key) { handle_key(cursor, anchor, key) },
    fn() { view(cursor, anchor) },
  )
}

fn handle_key(cursor: state.IntCell, anchor: state.IntCell, raw: String) -> Nil {
  let key = phase2_model.parse_key(raw)
  let pos = state.get_int(cursor)
  let anch = state.get_int(anchor)
  let len = string.length(sample_text)
  let sel = model.Selection(anch, pos)

  case key {
    phase2_model.ArrowRight -> {
      let next = phase2_model.clamp(pos + 1, 0, len)
      state.set_int(cursor, next)
      state.set_int(anchor, next)
    }
    phase2_model.ArrowLeft -> {
      let next = phase2_model.clamp(pos - 1, 0, len)
      state.set_int(cursor, next)
      state.set_int(anchor, next)
    }
    phase2_model.Home -> {
      state.set_int(cursor, 0)
      state.set_int(anchor, 0)
    }
    phase2_model.End -> {
      state.set_int(cursor, len)
      state.set_int(anchor, len)
    }
    phase2_model.Character("L") -> {
      let extended = model.extend_selection(sel, 1)
      state.set_int(cursor, phase2_model.clamp(extended.focus, 0, len))
    }
    phase2_model.Character("H") -> {
      let extended = model.extend_selection(sel, -1)
      state.set_int(cursor, phase2_model.clamp(extended.focus, 0, len))
    }
    phase2_model.Character("c") -> {
      let collapsed = model.collapse_selection(sel)
      state.set_int(cursor, collapsed.focus)
      state.set_int(anchor, collapsed.anchor)
    }
    _ -> Nil
  }
}

fn view(cursor: state.IntCell, anchor: state.IntCell) -> List(ui.Element) {
  let pos = state.get_int(cursor)
  let anch = state.get_int(anchor)
  let sel = model.Selection(anch, pos)
  let chars = string.to_graphemes(sample_text)

  [
    common.panel("Text", 2, 3, 76, 8, [
      ui.Column([ui.Gap(1)], [
        common.line(render_with_selection(chars, sel, 0, 36)),
        common.line(render_with_selection(chars, sel, 36, string.length(sample_text) - 36)),
      ]),
    ]),
    common.panel("Selection state", 2, 12, 38, 9, [
      ui.Column([ui.Gap(1)], [
        common.line("Anchor: " <> int.to_string(anch)),
        common.line("Focus:  " <> int.to_string(pos)),
        common.line("Length: " <> int.to_string(model.selection_length(sel))),
        common.line("Range:  " <> range_label(sel)),
        common.line(
          "Selected: "
          <> selected_text(chars, sel),
        ),
      ]),
    ]),
    common.panel("Controls", 42, 12, 36, 9, [
      ui.Column([ui.Gap(1)], [
        common.line("←/→     move cursor"),
        common.line("Shift+L  extend right"),
        common.line("Shift+H  extend left"),
        common.line("c        collapse"),
        common.line("Home/End jump"),
      ]),
    ]),
  ]
}

fn render_with_selection(
  chars: List(String),
  sel: model.Selection,
  offset: Int,
  count: Int,
) -> String {
  case count <= 0 || offset >= list.length(chars) {
    True -> ""
    False -> {
      let char = nth_char(chars, offset)
      let display = case model.selection_contains(sel, offset) {
        True -> "[" <> char <> "]"
        False ->
          case offset == sel.focus {
            True -> "█"
            False -> char
          }
      }
      display <> render_with_selection(chars, sel, offset + 1, count - 1)
    }
  }
}

fn nth_char(chars: List(String), index: Int) -> String {
  case chars, index {
    [c, ..], 0 -> c
    [_, ..rest], _ -> nth_char(rest, index - 1)
    [], _ -> " "
  }
}

fn selected_text(chars: List(String), sel: model.Selection) -> String {
  case model.selection_length(sel) {
    0 -> "(none)"
    _ -> {
      let #(lo, hi) = model.selection_range(sel)
      chars
      |> list.drop(lo)
      |> list.take(hi - lo)
      |> string.join("")
      |> string.slice(0, 20)
    }
  }
}

fn range_label(sel: model.Selection) -> String {
  let #(lo, hi) = model.selection_range(sel)
  int.to_string(lo) <> ".." <> int.to_string(hi)
}
