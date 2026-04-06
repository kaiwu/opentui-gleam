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

  common.run_interactive_demo(
    "HAST Syntax Highlighting",
    "HAST Syntax Highlighting",
    fn(key) {
      let k = phase2_model.parse_key(key)
      state.set_int(
        scroll,
        phase2_model.adjust_scroll(
          state.get_int(scroll),
          k,
          phase2_model.max_scroll_offset(list.length(code_lines()), 14),
        ),
      )
    },
    fn(buf) { draw_body(buf, scroll) },
  )
}

fn draw_body(buf: ffi.Buffer, scroll: state.IntCell) -> Nil {
  let offset = state.get_int(scroll)
  let lines = code_lines()
  let visible = phase2_model.visible_lines(lines, offset, 14)

  common.draw_panel(buf, 2, 3, 54, 18, "Source")
  draw_highlighted_lines(buf, visible, 0)

  common.draw_panel(buf, 58, 3, 20, 18, "Info")
  buffer.draw_text(buf, "Lines: " <> int.to_string(list.length(lines)), 60, 5, common.fg_color, common.panel_bg, 0)
  buffer.draw_text(buf, "Offset: " <> int.to_string(offset), 60, 6, common.fg_color, common.panel_bg, 0)
  buffer.draw_text(buf, "Up/Down scroll", 60, 8, common.muted_fg, common.panel_bg, 0)
  buffer.draw_text(buf, "Keyword-based", 60, 10, common.muted_fg, common.panel_bg, 0)
  buffer.draw_text(buf, "tokenizer drives", 60, 11, common.muted_fg, common.panel_bg, 0)
  buffer.draw_text(buf, "the highlighting.", 60, 12, common.muted_fg, common.panel_bg, 0)
  buffer.draw_text(buf, "No native syntax", 60, 14, common.muted_fg, common.panel_bg, 0)
  buffer.draw_text(buf, "engine — pure FP.", 60, 15, common.muted_fg, common.panel_bg, 0)
}

fn draw_highlighted_lines(buf: ffi.Buffer, lines: List(String), row: Int) -> Nil {
  case lines {
    [] -> Nil
    [line, ..rest] -> {
      let tokens = model.tokenize(line)
      draw_tokens(buf, tokens, 4, 5 + row)
      draw_highlighted_lines(buf, rest, row + 1)
    }
  }
}

fn draw_tokens(buf: ffi.Buffer, tokens: List(model.Token), x: Int, y: Int) -> Nil {
  case tokens {
    [] -> Nil
    [token, ..rest] -> {
      let color = token_color(token.style)
      let attrs = token_attrs(token.style)
      buffer.draw_text(buf, token.text, x, y, color, common.panel_bg, attrs)
      draw_tokens(buf, rest, x + string.length(token.text), y)
    }
  }
}

fn token_color(style: model.TokenStyle) -> #(Float, Float, Float, Float) {
  case style {
    model.Keyword -> common.accent_blue
    model.StringLit -> common.accent_green
    model.Comment -> common.muted_fg
    model.Punctuation -> common.border_fg
    model.Number -> common.accent_orange
    model.Normal -> common.fg_color
  }
}

fn token_attrs(style: model.TokenStyle) -> Int {
  case style {
    model.Keyword -> 1
    model.Comment -> 2
    _ -> 0
  }
}

fn code_lines() -> List(String) {
  [
    "import gleam/list",
    "import gleam/string",
    "",
    "pub type Element {",
    "  Box(List(Style), List(Element))",
    "  Text(List(Style), String)",
    "  Spacer(Int)",
    "}",
    "",
    "pub fn render(elements: List(Element)) {",
    "  list.map(elements, fn(el) {",
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
    "// Pure data — no side effects",
    "let count = 42",
    "let name = \"opentui\"",
  ]
}
