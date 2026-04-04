import opentui/examples/common
import opentui/text
import opentui/ui

const sample = "Gleam makes layout helpers easy to compose as pure functions. This demo shows the same paragraph rendered with no wrap, word wrap, and character wrap."

pub fn main() -> Nil {
  common.run_static_ui_demo("Text Wrap Demo", "Gleam Text Wrap Demo", view())
}

fn view() -> List(ui.Element) {
  [
    panel(2, "No wrap", text.wrap(sample, 18, text.NoWrap)),
    panel(28, "Word wrap", text.wrap(sample, 18, text.WordWrap)),
    panel(54, "Character wrap", text.wrap(sample, 18, text.CharacterWrap)),
  ]
}

fn panel(x: Int, title: String, lines: List(String)) -> ui.Element {
  ui.Box(
    ui.BoxProps(
      x,
      3,
      24,
      18,
      1,
      color(common.panel_bg),
      ui.HasBorder(title, color(common.border_fg)),
    ),
    [ui.Column(ui.ColumnProps(0), line_elements(lines))],
  )
}

fn line_elements(lines: List(String)) -> List(ui.Element) {
  case lines {
    [] -> []
    [line, ..rest] -> {
      let item =
        ui.Text(
          ui.TextProps(color(common.fg_color), color(common.panel_bg), 0),
          text.truncate_end(line, 18),
        )
      [item, ..line_elements(rest)]
    }
  }
}

fn color(c: #(Float, Float, Float, Float)) -> ui.Color {
  ui.Color(c.0, c.1, c.2, c.3)
}
