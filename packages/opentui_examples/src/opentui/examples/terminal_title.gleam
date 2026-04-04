import opentui/examples/common
import opentui/ui

pub fn main() -> Nil {
  common.run_static_ui_demo(
    "Terminal Title Demo",
    "Gleam Terminal Title Demo",
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
        ui.Height(16),
        ui.Padding(1),
        ui.Background(color(common.panel_bg)),
        ui.Border("Terminal Title", color(common.border_fg)),
      ],
      [
        ui.Column([ui.Gap(1)], [
          line("The terminal title for this demo was set from Gleam."),
          ui.Spacer(1),
          line("This mirrors the TypeScript terminal-title example"),
          ui.Spacer(1),
          line("using the Gleam renderer API."),
          ui.Spacer(1),
          line(
            "Check your terminal tab or window title while this demo is open.",
          ),
        ]),
      ],
    ),
  ]
}

fn line(content: String) -> ui.Element {
  ui.Text(
    [
      ui.Foreground(color(common.fg_color)),
      ui.Background(color(common.panel_bg)),
    ],
    content,
  )
}

fn color(c: #(Float, Float, Float, Float)) -> ui.Color {
  ui.Color(c.0, c.1, c.2, c.3)
}
