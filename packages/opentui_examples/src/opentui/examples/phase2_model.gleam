import gleam/list
import gleam/string

pub type Key {
  ArrowUp
  ArrowDown
  ArrowLeft
  ArrowRight
  Enter
  Tab
  ShiftTab
  Home
  End
  Backspace
  Space
  Character(String)
  Unknown(String)
}

pub fn parse_key(raw: String) -> Key {
  case raw {
    "\u{1b}[A" -> ArrowUp
    "\u{1b}[B" -> ArrowDown
    "\u{1b}[D" -> ArrowLeft
    "\u{1b}[C" -> ArrowRight
    "\u{1b}[H" | "\u{1b}[1~" -> Home
    "\u{1b}[F" | "\u{1b}[4~" -> End
    "\u{1b}[Z" -> ShiftTab
    "\r" | "\n" -> Enter
    "\t" -> Tab
    "\u{7f}" | "\u{8}" -> Backspace
    " " -> Space
    _ ->
      case string.length(raw) == 1 {
        True -> Character(raw)
        False -> Unknown(raw)
      }
  }
}

pub fn key_label(raw: String) -> String {
  case parse_key(raw) {
    ArrowUp -> "ArrowUp"
    ArrowDown -> "ArrowDown"
    ArrowLeft -> "ArrowLeft"
    ArrowRight -> "ArrowRight"
    Enter -> "Enter"
    Tab -> "Tab"
    ShiftTab -> "Shift+Tab"
    Home -> "Home"
    End -> "End"
    Backspace -> "Backspace"
    Space -> "Space"
    Character(value) -> "Character(" <> value <> ")"
    Unknown(value) -> "Unknown(" <> raw_label(value) <> ")"
  }
}

pub fn append_log(existing: String, entry: String, max_lines: Int) -> String {
  let lines = case existing == "" {
    True -> [entry]
    False -> list.append(string.split(existing, "\n"), [entry])
  }

  lines
  |> keep_last(max_lines)
  |> string.join(with: "\n")
}

pub fn navigate(index: Int, count: Int, key: Key) -> Int {
  case count <= 0 {
    True -> 0
    False ->
      case key {
        ArrowUp | ArrowLeft | ShiftTab -> cycle_prev(index, count)
        ArrowDown | ArrowRight | Tab -> cycle_next(index, count)
        Home -> 0
        End -> count - 1
        _ -> clamp(index, 0, count - 1)
      }
  }
}

pub fn adjust_slider(value: Int, key: Key) -> Int {
  case key {
    ArrowLeft -> clamp(value - 5, 0, 100)
    ArrowRight -> clamp(value + 5, 0, 100)
    Home -> 0
    End -> 100
    _ -> clamp(value, 0, 100)
  }
}

pub fn navigate_available(
  current: Int,
  availability: List(Bool),
  key: Key,
) -> Int {
  let base = restore_focus(current, availability)

  case key {
    ArrowUp | ArrowLeft | ShiftTab -> previous_available(availability, base, 1)
    ArrowDown | ArrowRight | Tab -> next_available(availability, base, 1)
    Home -> first_available(availability, 0)
    End -> last_available(availability, 0, 0)
    _ -> base
  }
}

pub fn adjust_scroll(offset: Int, key: Key, max_offset: Int) -> Int {
  case key {
    ArrowUp -> clamp(offset - 1, 0, max_offset)
    ArrowDown -> clamp(offset + 1, 0, max_offset)
    Home -> 0
    End -> max_offset
    _ -> clamp(offset, 0, max_offset)
  }
}

pub fn max_scroll_offset(total: Int, visible: Int) -> Int {
  clamp(total - visible, 0, total)
}

pub fn max_sticky_offset(total: Int, sticky_count: Int, body_count: Int) -> Int {
  max_scroll_offset(total - sticky_count, body_count)
}

pub fn visible_lines(
  lines: List(String),
  offset: Int,
  count: Int,
) -> List(String) {
  lines
  |> drop_lines(clamp(offset, 0, list.length(lines)))
  |> take_lines(count)
}

pub fn sticky_window(
  lines: List(String),
  sticky_count: Int,
  offset: Int,
  body_count: Int,
) -> #(List(String), List(String)) {
  let sticky = take_lines(lines, sticky_count)
  let scrollable = drop_lines(lines, sticky_count)
  #(sticky, visible_lines(scrollable, offset, body_count))
}

pub fn restore_focus(current: Int, availability: List(Bool)) -> Int {
  case is_available(availability, current) {
    True -> current
    False -> nearest_available(availability, current, 1)
  }
}

pub fn slider_bar(value: Int, width: Int) -> String {
  let safe_width = clamp(width, 1, width)
  let filled = clamp(value * safe_width / 100, 0, safe_width)
  repeat("=", filled) <> repeat("-", safe_width - filled)
}

pub fn split_divider(width: Int, key: Key) -> Int {
  case key {
    ArrowLeft -> clamp(width - 2, 18, 54)
    ArrowRight -> clamp(width + 2, 18, 54)
    Home -> 18
    End -> 54
    _ -> clamp(width, 18, 54)
  }
}

pub fn selection_marker(index: Int, focused: Int, selected: Int) -> String {
  case index == selected, index == focused {
    True, True -> "◉"
    True, False -> "●"
    False, True -> "›"
    False, False -> " "
  }
}

pub fn focus_marker(index: Int, focused: Int) -> String {
  case index == focused {
    True -> "›"
    False -> " "
  }
}

pub fn clamp(value: Int, minimum: Int, maximum: Int) -> Int {
  case value < minimum {
    True -> minimum
    False ->
      case value > maximum {
        True -> maximum
        False -> value
      }
  }
}

fn cycle_next(index: Int, count: Int) -> Int {
  case index + 1 >= count {
    True -> 0
    False -> index + 1
  }
}

fn cycle_prev(index: Int, count: Int) -> Int {
  case index <= 0 {
    True -> count - 1
    False -> index - 1
  }
}

fn keep_last(lines: List(String), max_lines: Int) -> List(String) {
  case list.length(lines) <= max_lines {
    True -> lines
    False ->
      case lines {
        [] -> []
        [_, ..rest] -> keep_last(rest, max_lines)
      }
  }
}

fn drop_lines(lines: List(String), count: Int) -> List(String) {
  case count <= 0, lines {
    True, _ -> lines
    False, [] -> []
    False, [_, ..rest] -> drop_lines(rest, count - 1)
  }
}

fn take_lines(lines: List(String), count: Int) -> List(String) {
  case count <= 0, lines {
    True, _ -> []
    False, [] -> []
    False, [line, ..rest] -> [line, ..take_lines(rest, count - 1)]
  }
}

fn is_available(availability: List(Bool), index: Int) -> Bool {
  case availability, index {
    [value, ..], 0 -> value
    [_, ..rest], _ if index > 0 -> is_available(rest, index - 1)
    _, _ -> False
  }
}

fn nearest_available(
  availability: List(Bool),
  current: Int,
  distance: Int,
) -> Int {
  case distance > list.length(availability) {
    True -> 0
    False -> {
      let right = current + distance
      let left = current - distance

      case is_available(availability, right) {
        True -> right
        False ->
          case is_available(availability, left) {
            True -> left
            False -> nearest_available(availability, current, distance + 1)
          }
      }
    }
  }
}

fn next_available(availability: List(Bool), current: Int, steps: Int) -> Int {
  case steps > list.length(availability) {
    True -> current
    False -> {
      let candidate = wrapped_index(current + steps, list.length(availability))
      case is_available(availability, candidate) {
        True -> candidate
        False -> next_available(availability, current, steps + 1)
      }
    }
  }
}

fn previous_available(availability: List(Bool), current: Int, steps: Int) -> Int {
  case steps > list.length(availability) {
    True -> current
    False -> {
      let candidate = wrapped_index(current - steps, list.length(availability))
      case is_available(availability, candidate) {
        True -> candidate
        False -> previous_available(availability, current, steps + 1)
      }
    }
  }
}

fn first_available(availability: List(Bool), index: Int) -> Int {
  case availability {
    [] -> 0
    [True, ..] -> index
    [False, ..rest] -> first_available(rest, index + 1)
  }
}

fn last_available(availability: List(Bool), index: Int, best: Int) -> Int {
  case availability {
    [] -> best
    [value, ..rest] ->
      case value {
        True -> last_available(rest, index + 1, index)
        False -> last_available(rest, index + 1, best)
      }
  }
}

fn wrapped_index(index: Int, count: Int) -> Int {
  case count <= 0 {
    True -> 0
    False ->
      case index < 0 {
        True -> count + index
        False ->
          case index >= count {
            True -> index - count
            False -> index
          }
      }
  }
}

fn repeat(segment: String, count: Int) -> String {
  case count <= 0 {
    True -> ""
    False -> segment <> repeat(segment, count - 1)
  }
}

fn raw_label(value: String) -> String {
  case value {
    "\u{1b}" -> "Escape"
    _ -> value
  }
}
