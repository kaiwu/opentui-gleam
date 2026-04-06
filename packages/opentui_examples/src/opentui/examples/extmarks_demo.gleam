import gleam/int
import gleam/list
import gleam/string
import opentui/examples/common
import opentui/examples/phase2_model
import opentui/examples/phase2_state as state
import opentui/examples/phase3_model as model
import opentui/ui

const sample_text = "let value = compute(input) // fast path"

pub fn main() -> Nil {
  let cursor = state.create_int(0)

  common.run_interactive_ui_demo(
    "Extmarks Demo",
    "Extmarks Demo",
    fn(key) { handle_key(cursor, key) },
    fn() { view(cursor) },
  )
}

fn handle_key(cursor: state.IntCell, raw: String) -> Nil {
  let key = phase2_model.parse_key(raw)
  let pos = state.get_int(cursor)
  let max = string.length(sample_text) - 1
  let marks = extmarks()

  case key {
    phase2_model.ArrowRight -> {
      let next = model.skip_extmark(marks, pos + 1, True)
      state.set_int(cursor, phase2_model.clamp(next, 0, max))
    }
    phase2_model.ArrowLeft -> {
      let next = case pos > 0 {
        True -> model.skip_extmark(marks, pos - 1, False)
        False -> 0
      }
      state.set_int(cursor, phase2_model.clamp(next, 0, max))
    }
    phase2_model.Home -> state.set_int(cursor, 0)
    phase2_model.End -> state.set_int(cursor, max)
    _ -> Nil
  }
}

fn view(cursor: state.IntCell) -> List(ui.Element) {
  let pos = state.get_int(cursor)
  let marks = extmarks()
  let chars = string.to_graphemes(sample_text)
  let label = model.extmark_label_at(marks, pos)
  let at_marks = model.extmarks_at(marks, pos)

  [
    common.panel("Text with Extmarks", 2, 3, 76, 7, [
      ui.Column([ui.Gap(1)], [
        common.line(render_chars(chars, marks, pos, 0)),
        common.line(render_marker_line(marks, pos, list.length(chars))),
      ]),
    ]),
    common.panel("Cursor", 2, 11, 38, 10, [
      ui.Column([ui.Gap(1)], [
        common.line("Position: " <> int.to_string(pos)),
        common.line("At mark: " <> case label {
          "" -> "(none)"
          l -> l
        }),
        common.line("Marks here: " <> int.to_string(list.length(at_marks))),
        ui.Spacer(1),
        common.paragraph(
          "Arrow keys skip over extmark ranges as atomic units. The cursor jumps from start to end (or vice versa) rather than traversing character by character.",
        ),
      ]),
    ]),
    common.panel("Extmark Ranges", 42, 11, 36, 10, [
      ui.Column([ui.Gap(0)], mark_info_lines(marks)),
    ]),
  ]
}

fn render_chars(
  chars: List(String),
  marks: List(model.Extmark),
  cursor: Int,
  pos: Int,
) -> String {
  case chars {
    [] -> ""
    [c, ..rest] -> {
      let display = case pos == cursor {
        True -> "█"
        False ->
          case model.extmarks_at(marks, pos) != [] {
            True -> c
            False -> c
          }
      }
      display <> render_chars(rest, marks, cursor, pos + 1)
    }
  }
}

fn render_marker_line(
  marks: List(model.Extmark),
  _cursor: Int,
  length: Int,
) -> String {
  render_marker_chars(marks, 0, length)
}

fn render_marker_chars(marks: List(model.Extmark), pos: Int, length: Int) -> String {
  case pos >= length {
    True -> ""
    False -> {
      let c = case model.extmarks_at(marks, pos) != [] {
        True -> "▔"
        False -> " "
      }
      c <> render_marker_chars(marks, pos + 1, length)
    }
  }
}

fn mark_info_lines(marks: List(model.Extmark)) -> List(ui.Element) {
  case marks {
    [] -> []
    [mark, ..rest] -> [
      common.line_with(
        [ui.Foreground(common.color(common.accent_yellow))],
        mark.label
          <> " ["
          <> int.to_string(mark.start)
          <> ".."
          <> int.to_string(mark.end)
          <> "]",
      ),
      ..mark_info_lines(rest)
    ]
  }
}

fn extmarks() -> List(model.Extmark) {
  [
    model.Extmark(4, 9, "identifier"),
    model.Extmark(12, 19, "function"),
    model.Extmark(27, 39, "comment"),
  ]
}
