import gleam/int
import gleam/list
import gleam/string
import opentui/text

pub type WrapMode {
  WordWrap
  CharacterWrap
  NoWrap
}

pub fn cycle_wrap_mode(mode: WrapMode) -> WrapMode {
  case mode {
    WordWrap -> CharacterWrap
    CharacterWrap -> NoWrap
    NoWrap -> WordWrap
  }
}

pub fn wrap_label(mode: WrapMode) -> String {
  case mode {
    WordWrap -> "word"
    CharacterWrap -> "char"
    NoWrap -> "none"
  }
}

pub fn use_editor_view(mode: WrapMode) -> Bool {
  case mode {
    CharacterWrap -> False
    _ -> True
  }
}

pub fn editor_view_wrap(mode: WrapMode) -> Bool {
  case mode {
    NoWrap -> False
    _ -> True
  }
}

pub fn logical_line_count(content: String) -> Int {
  list.length(string.split(content, "\n"))
}

pub fn gutter_width(total_lines: Int) -> Int {
  int.max(3, string.length(int.to_string(total_lines)))
}

pub fn visual_lines(content: String, width: Int, mode: WrapMode) -> List(String) {
  text.wrap(content, width, to_text_wrap(mode))
}

pub fn line_number_rows(
  content: String,
  width: Int,
  mode: WrapMode,
) -> List(String) {
  string.split(content, "\n")
  |> build_line_number_rows(width, mode, 1, [])
  |> list.reverse
}

pub fn status_text(
  row: Int,
  col: Int,
  mode: WrapMode,
  show_line_numbers: Bool,
  can_undo: Bool,
  can_redo: Bool,
) -> String {
  "Ln "
  <> int.to_string(row + 1)
  <> ", Col "
  <> int.to_string(col + 1)
  <> " | Wrap: "
  <> wrap_label(mode)
  <> " | Lines: "
  <> bool_label(show_line_numbers)
  <> " | Undo: "
  <> bool_label(can_undo)
  <> " | Redo: "
  <> bool_label(can_redo)
}

pub fn fit_status(status: String, max_width: Int) -> String {
  case max_width <= 0 {
    True -> ""
    False ->
      case string.length(status) <= max_width {
        True -> status
        False ->
          case max_width <= 3 {
            True -> string.slice(status, 0, max_width)
            False -> string.slice(status, 0, max_width - 3) <> "..."
          }
      }
  }
}

pub fn char_wrap_cursor(
  content: String,
  row: Int,
  col: Int,
  width: Int,
) -> #(Int, Int) {
  let lines = string.split(content, "\n")
  let visual_row = wrapped_rows_before(lines, row, width, 0, 0)

  case line_at(lines, row) {
    Ok(line) -> {
      let safe_col = clamp(col, 0, string.length(line))
      #(visual_row + safe_col / width, safe_col % width)
    }
    Error(_) -> #(visual_row, 0)
  }
}

fn build_line_number_rows(
  lines: List(String),
  width: Int,
  mode: WrapMode,
  line_no: Int,
  acc: List(String),
) -> List(String) {
  case lines {
    [] -> acc
    [line, ..rest] -> {
      let segments = visual_lines(line, width, mode)
      let next_acc = add_line_number_segments(segments, line_no, acc, True)
      build_line_number_rows(rest, width, mode, line_no + 1, next_acc)
    }
  }
}

fn add_line_number_segments(
  segments: List(String),
  line_no: Int,
  acc: List(String),
  first: Bool,
) -> List(String) {
  case segments {
    [] -> acc
    [_, ..rest] ->
      add_line_number_segments(
        rest,
        line_no,
        [
          case first {
            True -> int.to_string(line_no)
            False -> ""
          },
          ..acc
        ],
        False,
      )
  }
}

fn wrapped_rows_before(
  lines: List(String),
  target_row: Int,
  width: Int,
  current_row: Int,
  acc: Int,
) -> Int {
  case lines {
    [] -> acc
    [line, ..rest] ->
      case current_row == target_row {
        True -> acc
        False ->
          wrapped_rows_before(
            rest,
            target_row,
            width,
            current_row + 1,
            acc + list.length(visual_lines(line, width, CharacterWrap)),
          )
      }
  }
}

fn line_at(lines: List(String), index: Int) -> Result(String, Nil) {
  case lines, index {
    [line, ..], 0 -> Ok(line)
    [_, ..rest], _ if index > 0 -> line_at(rest, index - 1)
    _, _ -> Error(Nil)
  }
}

fn clamp(value: Int, minimum: Int, maximum: Int) -> Int {
  case value < minimum {
    True -> minimum
    False ->
      case value > maximum {
        True -> maximum
        False -> value
      }
  }
}

fn bool_label(value: Bool) -> String {
  case value {
    True -> "on"
    False -> "off"
  }
}

fn to_text_wrap(mode: WrapMode) -> text.WrapMode {
  case mode {
    WordWrap -> text.WordWrap
    CharacterWrap -> text.CharacterWrap
    NoWrap -> text.NoWrap
  }
}
