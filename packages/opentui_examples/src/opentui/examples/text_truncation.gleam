import opentui/examples/common
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
      [
        ui.X(2),
        ui.Y(3),
        ui.Width(76),
        ui.Height(18),
        ui.Padding(1),
        ui.Background(color(common.panel_bg)),
        ui.Border("Truncation strategies", color(common.border_fg)),
      ],
      [
        ui.Column([ui.Gap(2)], [
          line("Original:", 1),
          line(sample_sentence, 0),
          line("End:", 1),
          line_truncated(sample_path, ui.EndTruncate),
          line("Middle:", 1),
          line_truncated(sample_path, ui.MiddleTruncate),
          line("These helpers are pure Gleam functions reused across demos.", 0),
        ]),
      ],
    ),
  ]
}

fn line(content: String, attributes: Int) -> ui.Element {
  ui.Text(
    [
      ui.Foreground(color(common.fg_color)),
      ui.Background(color(common.panel_bg)),
      ui.Attributes(attributes),
      ui.Truncate(ui.EndTruncate),
    ],
    content,
  )
}

fn line_truncated(content: String, mode: ui.Truncation) -> ui.Element {
  ui.Text(
    [
      ui.Foreground(color(common.fg_color)),
      ui.Background(color(common.panel_bg)),
      ui.Truncate(mode),
    ],
    content,
  )
}

fn color(c: #(Float, Float, Float, Float)) -> ui.Color {
  ui.Color(c.0, c.1, c.2, c.3)
}
