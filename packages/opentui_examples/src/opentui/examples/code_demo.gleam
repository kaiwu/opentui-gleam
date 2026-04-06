import gleam/int
import gleam/list
import gleam/string
import opentui/buffer
import opentui/examples/common
import opentui/examples/phase2_model
import opentui/examples/phase2_state as state
import opentui/examples/phase3_model as model
import opentui/ffi

pub fn main() -> Nil {
  let scroll = state.create_int(0)
  let theme = state.create_int(0)

  common.run_interactive_demo(
    "Code Demo",
    "Code Demo",
    fn(key) { handle_key(scroll, theme, key) },
    fn(buf) { draw_body(buf, scroll, theme) },
  )
}

fn handle_key(
  scroll: state.IntCell,
  theme: state.IntCell,
  raw: String,
) -> Nil {
  let key = phase2_model.parse_key(raw)
  case key {
    phase2_model.Tab ->
      state.set_int(theme, { state.get_int(theme) + 1 } % 3)
    _ ->
      state.set_int(
        scroll,
        phase2_model.adjust_scroll(
          state.get_int(scroll),
          key,
          phase2_model.max_scroll_offset(list.length(code_lines()), 14),
        ),
      )
  }
}

fn draw_body(buf: ffi.Buffer, scroll: state.IntCell, theme: state.IntCell) -> Nil {
  let offset = state.get_int(scroll)
  let theme_idx = state.get_int(theme)
  let lines = code_lines()
  let visible = phase2_model.visible_lines(lines, offset, 14)

  common.draw_panel(buf, 2, 3, 56, 18, "Code — " <> theme_name(theme_idx))
  draw_code_lines(buf, visible, offset, theme_idx, 0)

  common.draw_panel(buf, 60, 3, 18, 18, "Info")
  buffer.draw_text(buf, "Lines: " <> int.to_string(list.length(lines)), 62, 5, common.fg_color, common.panel_bg, 0)
  buffer.draw_text(buf, "Offset: " <> int.to_string(offset), 62, 6, common.fg_color, common.panel_bg, 0)
  buffer.draw_text(buf, "Theme: " <> int.to_string(theme_idx + 1) <> "/3", 62, 7, common.fg_color, common.panel_bg, 0)
  buffer.draw_text(buf, "Up/Down scroll", 62, 9, common.muted_fg, common.panel_bg, 0)
  buffer.draw_text(buf, "Tab  theme", 62, 10, common.muted_fg, common.panel_bg, 0)
  buffer.draw_text(buf, "Tokenizer +", 62, 12, common.muted_fg, common.panel_bg, 0)
  buffer.draw_text(buf, "line numbers +", 62, 13, common.muted_fg, common.panel_bg, 0)
  buffer.draw_text(buf, "theme map.", 62, 14, common.muted_fg, common.panel_bg, 0)
}

fn draw_code_lines(
  buf: ffi.Buffer,
  lines: List(String),
  base_line: Int,
  theme_idx: Int,
  row: Int,
) -> Nil {
  case lines {
    [] -> Nil
    [line, ..rest] -> {
      let line_no = base_line + row + 1
      let gutter = string.pad_start(int.to_string(line_no), 3, " ")
      buffer.draw_text(buf, gutter, 4, 5 + row, common.muted_fg, common.panel_bg, 0)
      buffer.draw_text(buf, "│", 8, 5 + row, common.border_fg, common.panel_bg, 0)
      let tokens = model.tokenize(line)
      draw_themed_tokens(buf, tokens, 10, 5 + row, theme_idx)
      draw_code_lines(buf, rest, base_line, theme_idx, row + 1)
    }
  }
}

fn draw_themed_tokens(
  buf: ffi.Buffer,
  tokens: List(model.Token),
  x: Int,
  y: Int,
  theme_idx: Int,
) -> Nil {
  case tokens {
    [] -> Nil
    [token, ..rest] -> {
      let color = theme_color(theme_idx, token.style)
      let attrs = case token.style {
        model.Keyword -> 1
        model.Comment -> 2
        _ -> 0
      }
      buffer.draw_text(buf, token.text, x, y, color, common.panel_bg, attrs)
      draw_themed_tokens(buf, rest, x + string.length(token.text), y, theme_idx)
    }
  }
}

fn theme_color(
  idx: Int,
  style: model.TokenStyle,
) -> #(Float, Float, Float, Float) {
  case idx {
    0 -> dark_theme(style)
    1 -> warm_theme(style)
    _ -> cool_theme(style)
  }
}

fn dark_theme(style: model.TokenStyle) -> #(Float, Float, Float, Float) {
  case style {
    model.Keyword -> #(0.33, 0.57, 0.98, 1.0)
    model.StringLit -> #(0.36, 0.82, 0.58, 1.0)
    model.Comment -> #(0.55, 0.58, 0.65, 1.0)
    model.Punctuation -> #(0.72, 0.75, 0.82, 1.0)
    model.Number -> #(0.94, 0.66, 0.31, 1.0)
    model.Normal -> #(0.95, 0.95, 0.98, 1.0)
  }
}

fn warm_theme(style: model.TokenStyle) -> #(Float, Float, Float, Float) {
  case style {
    model.Keyword -> #(0.98, 0.42, 0.42, 1.0)
    model.StringLit -> #(0.96, 0.82, 0.36, 1.0)
    model.Comment -> #(0.6, 0.55, 0.5, 1.0)
    model.Punctuation -> #(0.75, 0.7, 0.65, 1.0)
    model.Number -> #(0.88, 0.56, 0.82, 1.0)
    model.Normal -> #(0.93, 0.9, 0.85, 1.0)
  }
}

fn cool_theme(style: model.TokenStyle) -> #(Float, Float, Float, Float) {
  case style {
    model.Keyword -> #(0.62, 0.45, 0.92, 1.0)
    model.StringLit -> #(0.4, 0.78, 0.82, 1.0)
    model.Comment -> #(0.5, 0.55, 0.6, 1.0)
    model.Punctuation -> #(0.65, 0.7, 0.78, 1.0)
    model.Number -> #(0.92, 0.72, 0.42, 1.0)
    model.Normal -> #(0.88, 0.9, 0.95, 1.0)
  }
}

fn theme_name(idx: Int) -> String {
  case idx {
    0 -> "Dark"
    1 -> "Warm"
    _ -> "Cool"
  }
}

fn code_lines() -> List(String) {
  [
    "import gleam/list",
    "import gleam/int",
    "import gleam/string",
    "",
    "pub type Color {",
    "  Color(Float, Float, Float, Float)",
    "}",
    "",
    "pub type Style {",
    "  Foreground(Color)",
    "  Background(Color)",
    "  Attributes(Int)",
    "  Width(Int)",
    "  Height(Int)",
    "}",
    "",
    "pub type Element {",
    "  Box(List(Style), List(Element))",
    "  Text(List(Style), String)",
    "  Spacer(Int)",
    "}",
    "",
    "// Render an element tree to a buffer",
    "pub fn render(elements: List(Element)) {",
    "  list.each(elements, fn(el) {",
    "    case el {",
    "      Box(styles, children) ->",
    "        render_box(styles, children)",
    "      Text(styles, content) ->",
    "        render_text(styles, content)",
    "      Spacer(height) -> height",
    "    }",
    "  })",
    "}",
    "",
    "let count = 42",
    "let label = \"hello world\"",
  ]
}
