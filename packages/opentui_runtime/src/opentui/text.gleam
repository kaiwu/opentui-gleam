import gleam/int
import gleam/list
import gleam/string

pub type WrapMode {
  NoWrap
  WordWrap
  CharacterWrap
}

pub fn wrap(text: String, width: Int, mode: WrapMode) -> List(String) {
  case width <= 0 {
    True -> [""]
    False ->
      text
      |> string.split("\n")
      |> list.flat_map(fn(line) { wrap_line(line, width, mode) })
  }
}

pub fn truncate_end(text: String, width: Int) -> String {
  case string.length(text) <= width {
    True -> text
    False ->
      case width <= 0 {
        True -> ""
        False ->
          case width == 1 {
            True -> "…"
            False -> string.slice(text, 0, width - 1) <> "…"
          }
      }
  }
}

pub fn truncate_middle(text: String, width: Int) -> String {
  case string.length(text) <= width {
    True -> text
    False ->
      case width <= 0 {
        True -> ""
        False ->
          case width == 1 {
            True -> "…"
            False -> {
              let available = width - 1
              let assert Ok(head) = int.divide(available, by: 2)
              let tail = available - head
              let len = string.length(text)
              string.slice(text, 0, head)
              <> "…"
              <> string.slice(text, len - tail, tail)
            }
          }
      }
  }
}

fn wrap_line(line: String, width: Int, mode: WrapMode) -> List(String) {
  case mode {
    NoWrap -> [line]
    CharacterWrap -> character_wrap(line, width)
    WordWrap -> word_wrap(line, width)
  }
}

fn character_wrap(line: String, width: Int) -> List(String) {
  case string.length(line) <= width {
    True -> [line]
    False -> [
      string.slice(line, 0, width),
      ..character_wrap(
        string.slice(line, width, string.length(line) - width),
        width,
      )
    ]
  }
}

fn word_wrap(line: String, width: Int) -> List(String) {
  case line {
    "" -> [""]
    _ ->
      line
      |> string.split(" ")
      |> wrap_words(width, "", [])
      |> list.reverse
  }
}

fn wrap_words(
  words: List(String),
  width: Int,
  current: String,
  acc: List(String),
) -> List(String) {
  case words {
    [] ->
      case current {
        "" -> acc
        _ -> [current, ..acc]
      }

    [word, ..rest] ->
      case current {
        "" -> wrap_words(rest, width, word, acc)
        _ -> {
          let candidate = current <> " " <> word
          case string.length(candidate) <= width {
            True -> wrap_words(rest, width, candidate, acc)
            False -> wrap_words(rest, width, word, [current, ..acc])
          }
        }
      }
  }
}
