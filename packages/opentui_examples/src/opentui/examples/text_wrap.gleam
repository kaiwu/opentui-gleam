import opentui/examples/common
import opentui/text
import opentui/ui

const sample = "Gleam makes layout helpers easy to compose as pure functions. This demo shows the same paragraph rendered with no wrap, word wrap, and character wrap."

pub fn main() -> Nil {
  common.run_static_ui_demo("Text Wrap Demo", "Gleam Text Wrap Demo", view())
}

fn view() -> List(ui.Element) {
  [
    panel(2, "No wrap", ui.Wrap(text.NoWrap)),
    panel(28, "Word wrap", ui.Wrap(text.WordWrap)),
    panel(54, "Character wrap", ui.Wrap(text.CharacterWrap)),
  ]
}

fn panel(x: Int, title: String, wrap: ui.Style) -> ui.Element {
  ui.Box(
    [
      ui.X(x),
      ui.Y(3),
      ui.Width(24),
      ui.Height(18),
      ui.Padding(1),
      ui.Background(color(common.panel_bg)),
      ui.Border(title, color(common.border_fg)),
    ],
    [
      ui.Paragraph(
        [
          ui.Foreground(color(common.fg_color)),
          ui.Background(color(common.panel_bg)),
          wrap,
          ui.MaxLines(14),
          ui.Truncate(ui.EndTruncate),
        ],
        sample,
      ),
    ],
  )
}

fn color(c: #(Float, Float, Float, Float)) -> ui.Color {
  ui.Color(c.0, c.1, c.2, c.3)
}
