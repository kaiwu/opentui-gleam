import gleam/int
import gleam/list
import gleam/string

// ---------------------------------------------------------------------------
// Log
// ---------------------------------------------------------------------------

pub type LogLevel {
  Debug
  Info
  Warn
  ErrorLevel
}

pub type LogEntry {
  LogEntry(level: LogLevel, message: String)
}

pub fn level_label(level: LogLevel) -> String {
  case level {
    Debug -> "DEBUG"
    Info -> "INFO"
    Warn -> "WARN"
    ErrorLevel -> "ERROR"
  }
}

pub fn level_color_index(level: LogLevel) -> Int {
  case level {
    Debug -> 0
    Info -> 1
    Warn -> 2
    ErrorLevel -> 3
  }
}

pub fn append_entry(
  entries: List(LogEntry),
  entry: LogEntry,
  max: Int,
) -> List(LogEntry) {
  list.append(entries, [entry])
  |> keep_last_entries(max)
}

pub fn format_entry(entry: LogEntry, index: Int) -> String {
  "["
  <> int.to_string(index)
  <> "] "
  <> level_label(entry.level)
  <> "  "
  <> entry.message
}

// ---------------------------------------------------------------------------
// Selection
// ---------------------------------------------------------------------------

pub type Selection {
  Selection(anchor: Int, focus: Int)
}

pub fn selection_range(sel: Selection) -> #(Int, Int) {
  case sel.anchor <= sel.focus {
    True -> #(sel.anchor, sel.focus)
    False -> #(sel.focus, sel.anchor)
  }
}

pub fn extend_selection(sel: Selection, delta: Int) -> Selection {
  Selection(anchor: sel.anchor, focus: sel.focus + delta)
}

pub fn collapse_selection(sel: Selection) -> Selection {
  Selection(anchor: sel.focus, focus: sel.focus)
}

pub fn selection_contains(sel: Selection, pos: Int) -> Bool {
  let #(lo, hi) = selection_range(sel)
  pos >= lo && pos < hi
}

pub fn selection_length(sel: Selection) -> Int {
  let #(lo, hi) = selection_range(sel)
  hi - lo
}

// ---------------------------------------------------------------------------
// Token / Syntax
// ---------------------------------------------------------------------------

pub type TokenStyle {
  Keyword
  StringLit
  Comment
  Punctuation
  Number
  Normal
}

pub type Token {
  Token(text: String, style: TokenStyle)
}

pub fn tokenize(line: String) -> List(Token) {
  tokenize_chars(string.to_graphemes(line), "", [])
  |> list.reverse
}

pub fn token_text(tokens: List(Token)) -> String {
  tokens
  |> list.map(fn(t) { t.text })
  |> string.join("")
}

// ---------------------------------------------------------------------------
// Table
// ---------------------------------------------------------------------------

pub type Alignment {
  AlignLeft
  AlignCenter
  AlignRight
}

pub fn column_widths(
  headers: List(String),
  rows: List(List(String)),
  min_col: Int,
) -> List(Int) {
  let header_widths = list.map(headers, string.length)
  let max_per_col =
    list.fold(rows, header_widths, fn(acc, row) {
      zip_max(acc, list.map(row, string.length))
    })
  list.map(max_per_col, fn(w) { int.max(w, min_col) })
}

pub fn pad_cell(text: String, width: Int, align: Alignment) -> String {
  let len = string.length(text)
  let pad = int.max(width - len, 0)
  case align {
    AlignLeft -> text <> spaces(pad)
    AlignRight -> spaces(pad) <> text
    AlignCenter -> {
      let left = pad / 2
      let right = pad - left
      spaces(left) <> text <> spaces(right)
    }
  }
}

pub fn format_row(
  cells: List(String),
  widths: List(Int),
  aligns: List(Alignment),
) -> String {
  "│ "
  <> format_cells(cells, widths, aligns)
  <> " │"
}

pub fn format_separator(widths: List(Int)) -> String {
  "├─"
  <> widths
  |> list.map(fn(w) { repeat_str("─", w) })
  |> string.join("─┼─")
  <> "─┤"
}

pub fn format_table_top(widths: List(Int)) -> String {
  "┌─"
  <> widths
  |> list.map(fn(w) { repeat_str("─", w) })
  |> string.join("─┬─")
  <> "─┐"
}

pub fn format_table_bottom(widths: List(Int)) -> String {
  "└─"
  <> widths
  |> list.map(fn(w) { repeat_str("─", w) })
  |> string.join("─┴─")
  <> "─┘"
}

pub fn format_table(
  headers: List(String),
  rows: List(List(String)),
  aligns: List(Alignment),
) -> List(String) {
  let widths = column_widths(headers, rows, 3)
  [
    format_table_top(widths),
    format_row(headers, widths, aligns),
    format_separator(widths),
    ..list.append(
      list.map(rows, fn(row) { format_row(row, widths, aligns) }),
      [format_table_bottom(widths)],
    )
  ]
}

// ---------------------------------------------------------------------------
// Diff
// ---------------------------------------------------------------------------

pub type DiffKind {
  Added
  Removed
  Context
  DiffHeader
}

pub type DiffLine {
  DiffLine(kind: DiffKind, content: String, line_no: Int)
}

pub fn parse_unified_diff(text: String) -> List(DiffLine) {
  text
  |> string.split("\n")
  |> classify_diff_lines(1, [])
  |> list.reverse
}

pub fn diff_prefix(kind: DiffKind) -> String {
  case kind {
    Added -> "+"
    Removed -> "-"
    DiffHeader -> "@@"
    Context -> " "
  }
}

// ---------------------------------------------------------------------------
// Markdown
// ---------------------------------------------------------------------------

pub type MdBlock {
  MdHeading(level: Int, text: String)
  MdParagraph(String)
  MdCodeBlock(lang: String, code: String)
  MdBulletList(List(String))
  MdHRule
}

pub fn parse_markdown_blocks(text: String) -> List(MdBlock) {
  text
  |> string.split("\n")
  |> parse_md_lines([], [])
  |> list.reverse
}

// ---------------------------------------------------------------------------
// Extmark
// ---------------------------------------------------------------------------

pub type Extmark {
  Extmark(start: Int, end: Int, label: String)
}

pub fn extmarks_at(marks: List(Extmark), pos: Int) -> List(Extmark) {
  list.filter(marks, fn(m) { pos >= m.start && pos < m.end })
}

pub fn skip_extmark(marks: List(Extmark), pos: Int, forward: Bool) -> Int {
  case extmarks_at(marks, pos) {
    [] -> pos
    [first, ..] ->
      case forward {
        True -> first.end
        False -> first.start - 1
      }
  }
}

pub fn extmark_label_at(marks: List(Extmark), pos: Int) -> String {
  case extmarks_at(marks, pos) {
    [] -> ""
    [first, ..] -> first.label
  }
}

// ---------------------------------------------------------------------------
// ASCII Art
// ---------------------------------------------------------------------------

pub fn ascii_big(char: String) -> List(String) {
  case string.uppercase(char) {
    "A" -> ["  █  ", " █ █ ", "█████", "█   █", "█   █"]
    "B" -> ["████ ", "█   █", "████ ", "█   █", "████ "]
    "C" -> [" ████", "█    ", "█    ", "█    ", " ████"]
    "D" -> ["████ ", "█   █", "█   █", "█   █", "████ "]
    "E" -> ["█████", "█    ", "████ ", "█    ", "█████"]
    "F" -> ["█████", "█    ", "████ ", "█    ", "█    "]
    "G" -> [" ████", "█    ", "█  ██", "█   █", " ████"]
    "H" -> ["█   █", "█   █", "█████", "█   █", "█   █"]
    "I" -> ["█████", "  █  ", "  █  ", "  █  ", "█████"]
    "J" -> ["█████", "    █", "    █", "█   █", " ███ "]
    "K" -> ["█   █", "█  █ ", "███  ", "█  █ ", "█   █"]
    "L" -> ["█    ", "█    ", "█    ", "█    ", "█████"]
    "M" -> ["█   █", "██ ██", "█ █ █", "█   █", "█   █"]
    "N" -> ["█   █", "██  █", "█ █ █", "█  ██", "█   █"]
    "O" -> [" ███ ", "█   █", "█   █", "█   █", " ███ "]
    "P" -> ["████ ", "█   █", "████ ", "█    ", "█    "]
    "Q" -> [" ███ ", "█   █", "█ █ █", "█  █ ", " ██ █"]
    "R" -> ["████ ", "█   █", "████ ", "█  █ ", "█   █"]
    "S" -> [" ████", "█    ", " ███ ", "    █", "████ "]
    "T" -> ["█████", "  █  ", "  █  ", "  █  ", "  █  "]
    "U" -> ["█   █", "█   █", "█   █", "█   █", " ███ "]
    "V" -> ["█   █", "█   █", "█   █", " █ █ ", "  █  "]
    "W" -> ["█   █", "█   █", "█ █ █", "██ ██", "█   █"]
    "X" -> ["█   █", " █ █ ", "  █  ", " █ █ ", "█   █"]
    "Y" -> ["█   █", " █ █ ", "  █  ", "  █  ", "  █  "]
    "Z" -> ["█████", "   █ ", "  █  ", " █   ", "█████"]
    "0" -> [" ███ ", "█  ██", "█ █ █", "██  █", " ███ "]
    "1" -> [" ██  ", "  █  ", "  █  ", "  █  ", "█████"]
    "2" -> [" ███ ", "█   █", "  ██ ", " █   ", "█████"]
    "3" -> ["████ ", "    █", " ███ ", "    █", "████ "]
    "4" -> ["█   █", "█   █", "█████", "    █", "    █"]
    "5" -> ["█████", "█    ", "████ ", "    █", "████ "]
    "6" -> [" ███ ", "█    ", "████ ", "█   █", " ███ "]
    "7" -> ["█████", "    █", "   █ ", "  █  ", "  █  "]
    "8" -> [" ███ ", "█   █", " ███ ", "█   █", " ███ "]
    "9" -> [" ███ ", "█   █", " ████", "    █", " ███ "]
    " " -> ["     ", "     ", "     ", "     ", "     "]
    "!" -> ["  █  ", "  █  ", "  █  ", "     ", "  █  "]
    _ -> ["     ", "     ", "  ?  ", "     ", "     "]
  }
}

pub fn ascii_banner(text: String) -> List(String) {
  let glyphs =
    text
    |> string.to_graphemes
    |> list.map(ascii_big)
  merge_glyph_rows(glyphs, 0, [])
  |> list.reverse
}

// ---------------------------------------------------------------------------
// Slot composition
// ---------------------------------------------------------------------------

pub type Slot {
  Slot(name: String, enabled: Bool)
}

pub fn active_slots(slots: List(Slot)) -> List(Slot) {
  list.filter(slots, fn(s) { s.enabled })
}

pub fn toggle_slot(slots: List(Slot), name: String) -> List(Slot) {
  list.map(slots, fn(s) {
    case s.name == name {
      True -> Slot(s.name, !s.enabled)
      False -> s
    }
  })
}

pub fn slot_names(slots: List(Slot)) -> List(String) {
  list.map(slots, fn(s) { s.name })
}

// ---------------------------------------------------------------------------
// Internal helpers
// ---------------------------------------------------------------------------

fn keep_last_entries(entries: List(LogEntry), max: Int) -> List(LogEntry) {
  case list.length(entries) <= max {
    True -> entries
    False ->
      case entries {
        [] -> []
        [_, ..rest] -> keep_last_entries(rest, max)
      }
  }
}

fn spaces(n: Int) -> String {
  repeat_str(" ", n)
}

fn repeat_str(s: String, n: Int) -> String {
  case n <= 0 {
    True -> ""
    False -> s <> repeat_str(s, n - 1)
  }
}

fn zip_max(a: List(Int), b: List(Int)) -> List(Int) {
  case a, b {
    [], [] -> []
    [x, ..ra], [] -> [x, ..zip_max(ra, [])]
    [], [y, ..rb] -> [y, ..zip_max([], rb)]
    [x, ..ra], [y, ..rb] -> [int.max(x, y), ..zip_max(ra, rb)]
  }
}

fn format_cells(
  cells: List(String),
  widths: List(Int),
  aligns: List(Alignment),
) -> String {
  case cells, widths, aligns {
    [], _, _ -> ""
    [c], [w], [a] -> pad_cell(c, w, a)
    [c], [w], _ -> pad_cell(c, w, AlignLeft)
    [c, ..rc], [w, ..rw], [a, ..ra] ->
      pad_cell(c, w, a) <> " │ " <> format_cells(rc, rw, ra)
    [c, ..rc], [w, ..rw], _ ->
      pad_cell(c, w, AlignLeft) <> " │ " <> format_cells(rc, rw, [])
    _, _, _ -> ""
  }
}

fn classify_diff_lines(
  lines: List(String),
  line_no: Int,
  acc: List(DiffLine),
) -> List(DiffLine) {
  case lines {
    [] -> acc
    [line, ..rest] -> {
      let kind = case string.starts_with(line, "@@") {
        True -> DiffHeader
        False ->
          case string.starts_with(line, "+") {
            True -> Added
            False ->
              case string.starts_with(line, "-") {
                True -> Removed
                False -> Context
              }
          }
      }
      classify_diff_lines(rest, line_no + 1, [
        DiffLine(kind, line, line_no),
        ..acc
      ])
    }
  }
}

fn parse_md_lines(
  lines: List(String),
  pending: List(String),
  acc: List(MdBlock),
) -> List(MdBlock) {
  case lines {
    [] -> flush_paragraph(pending, acc)
    [line, ..rest] -> {
      case classify_md_line(line) {
        #("heading", level, text) ->
          parse_md_lines(
            rest,
            [],
            [MdHeading(level, text), ..flush_paragraph(pending, acc)],
          )
        #("hrule", _, _) ->
          parse_md_lines(
            rest,
            [],
            [MdHRule, ..flush_paragraph(pending, acc)],
          )
        #("bullet", _, text) -> {
          let #(items, remaining) = collect_bullets(rest, [text])
          parse_md_lines(
            remaining,
            [],
            [MdBulletList(list.reverse(items)), ..flush_paragraph(pending, acc)],
          )
        }
        #("code_fence", _, lang) -> {
          let #(code, remaining) = collect_code(rest, [])
          parse_md_lines(
            remaining,
            [],
            [
              MdCodeBlock(lang, string.join(list.reverse(code), "\n")),
              ..flush_paragraph(pending, acc)
            ],
          )
        }
        #("blank", _, _) -> parse_md_lines(rest, [], flush_paragraph(pending, acc))
        _ -> parse_md_lines(rest, [line, ..pending], acc)
      }
    }
  }
}

fn classify_md_line(line: String) -> #(String, Int, String) {
  case string.starts_with(line, "```") {
    True -> #("code_fence", 0, string.drop_start(line, 3))
    False ->
      case string.starts_with(line, "---") {
        True ->
          case string.trim(line) == string.repeat("-", string.length(string.trim(line))) {
            True -> #("hrule", 0, "")
            False -> #("text", 0, line)
          }
        False ->
          case string.starts_with(line, "- ") {
            True -> #("bullet", 0, string.drop_start(line, 2))
            False ->
              case string.starts_with(line, "# ") {
                True -> #("heading", 1, string.drop_start(line, 2))
                False ->
                  case string.starts_with(line, "## ") {
                    True -> #("heading", 2, string.drop_start(line, 3))
                    False ->
                      case string.starts_with(line, "### ") {
                        True -> #("heading", 3, string.drop_start(line, 4))
                        False ->
                          case string.trim(line) == "" {
                            True -> #("blank", 0, "")
                            False -> #("text", 0, line)
                          }
                      }
                  }
              }
          }
      }
  }
}

fn flush_paragraph(
  pending: List(String),
  acc: List(MdBlock),
) -> List(MdBlock) {
  case pending {
    [] -> acc
    _ -> [
      MdParagraph(
        pending
        |> list.reverse
        |> string.join(" "),
      ),
      ..acc
    ]
  }
}

fn collect_bullets(
  lines: List(String),
  items: List(String),
) -> #(List(String), List(String)) {
  case lines {
    [] -> #(items, [])
    [line, ..rest] ->
      case string.starts_with(line, "- ") {
        True -> collect_bullets(rest, [string.drop_start(line, 2), ..items])
        False -> #(items, lines)
      }
  }
}

fn collect_code(
  lines: List(String),
  code: List(String),
) -> #(List(String), List(String)) {
  case lines {
    [] -> #(code, [])
    [line, ..rest] ->
      case string.starts_with(line, "```") {
        True -> #(code, rest)
        False -> collect_code(rest, [line, ..code])
      }
  }
}

fn is_keyword(word: String) -> Bool {
  case word {
    "pub" | "fn" | "let" | "case" | "import" | "type" | "if" | "else"
    | "as" | "assert" | "const" | "external" | "opaque" | "use" | "panic"
    | "True" | "False" | "Ok" | "Error" | "Nil" -> True
    _ -> False
  }
}

fn is_digit_string(s: String) -> Bool {
  case string.to_graphemes(s) {
    [] -> False
    chars -> list.all(chars, is_digit_char)
  }
}

fn is_digit_char(c: String) -> Bool {
  case c {
    "0" | "1" | "2" | "3" | "4" | "5" | "6" | "7" | "8" | "9" -> True
    _ -> False
  }
}

fn is_punctuation_char(c: String) -> Bool {
  case c {
    "(" | ")" | "{" | "}" | "[" | "]" | "," | "." | ":" | ";" | "=" | "|"
    | "-" | ">" | "<" | "+" | "*" | "/" | "!" | "&" | "#" | "@" | "~" -> True
    _ -> False
  }
}

fn tokenize_chars(
  chars: List(String),
  current: String,
  acc: List(Token),
) -> List(Token) {
  case chars {
    [] -> flush_token(current, acc)
    ["/", "/", ..rest] -> {
      let comment_text =
        "//" <> string.join(rest, "")
      [Token(comment_text, Comment), ..flush_token(current, acc)]
    }
    ["\"", ..rest] -> {
      let #(str_content, remaining) = collect_string(rest, "\"")
      tokenize_chars(
        remaining,
        "",
        [Token(str_content, StringLit), ..flush_token(current, acc)],
      )
    }
    [" ", ..rest] ->
      tokenize_chars(rest, "", [Token(" ", Normal), ..flush_token(current, acc)])
    [c, ..rest] ->
      case is_punctuation_char(c) {
        True ->
          tokenize_chars(rest, "", [
            Token(c, Punctuation),
            ..flush_token(current, acc)
          ])
        False -> tokenize_chars(rest, current <> c, acc)
      }
  }
}

fn flush_token(current: String, acc: List(Token)) -> List(Token) {
  case current {
    "" -> acc
    _ -> {
      let style = case is_keyword(current) {
        True -> Keyword
        False ->
          case is_digit_string(current) {
            True -> Number
            False -> Normal
          }
      }
      [Token(current, style), ..acc]
    }
  }
}

fn collect_string(
  chars: List(String),
  prefix: String,
) -> #(String, List(String)) {
  case chars {
    [] -> #(prefix, [])
    ["\"", ..rest] -> #(prefix <> "\"", rest)
    [c, ..rest] -> collect_string(rest, prefix <> c)
  }
}

fn merge_glyph_rows(
  glyphs: List(List(String)),
  row: Int,
  acc: List(String),
) -> List(String) {
  case row >= 5 {
    True -> acc
    False -> {
      let line =
        glyphs
        |> list.map(fn(g) { nth_or(g, row, "     ") })
        |> string.join(" ")
      merge_glyph_rows(glyphs, row + 1, [line, ..acc])
    }
  }
}

fn nth_or(items: List(String), index: Int, default: String) -> String {
  case items, index {
    [], _ -> default
    [item, ..], 0 -> item
    [_, ..rest], _ -> nth_or(rest, index - 1, default)
  }
}
