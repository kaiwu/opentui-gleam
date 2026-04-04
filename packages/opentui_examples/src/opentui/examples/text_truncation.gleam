import opentui/examples/common
import opentui/text
import opentui/ui

const sample_path = "/very/long/project/path/examples/opentui/demo/with/a/really/long/file-name.gleam"

const sample_sentence = "This is a very long line of demo text that should be truncated cleanly in a narrow panel."

pub fn main() -> Nil {
  common.run_static_ui_demo(
    "Text Truncation Demo",
    "Gleam Text Truncation Demo",
    view(),
  )
}

fn view() -> List(ui.Element) {
  [
    ui.Box(
      ui.BoxProps(
        2,
        3,
        76,
        18,
        1,
        color(common.panel_bg),
        ui.HasBorder("Truncation strategies", color(common.border_fg)),
      ),
      [
        ui.Column(ui.ColumnProps(2), [
          line("Original:", 1),
          line(text.truncate_end(sample_sentence, 64), 0),
          line("End:", 1),
          line(text.truncate_end(sample_path, 52), 0),
          line("Middle:", 1),
          line(text.truncate_middle(sample_path, 52), 0),
          line("These helpers are pure Gleam functions reused across demos.", 0),
        ]),
      ],
    ),
  ]
}

fn line(content: String, attributes: Int) -> ui.Element {
  ui.Text(
    ui.TextProps(color(common.fg_color), color(common.panel_bg), attributes),
    content,
  )
}

fn color(c: #(Float, Float, Float, Float)) -> ui.Color {
  ui.Color(c.0, c.1, c.2, c.3)
}
