import opentui/examples/common
import opentui/ui

pub fn main() -> Nil {
  common.run_static_ui_demo(
    "Relative Positioning Demo",
    "Relative Positioning Demo",
    view(),
  )
}

pub fn view() -> List(ui.Element) {
  [
    common.panel("Parent frame", 2, 3, 36, 18, [relative_chain()]),
    common.panel("Offsets", 42, 3, 36, 18, [
      ui.Column([ui.Gap(1)], [
        common.line_with(
          [ui.Attributes(1)],
          "Each child resolves from its parent.",
        ),
        common.paragraph(
          "The blue card is placed inside the panel, the green card is placed inside the blue card, and the orange badge is placed inside the green card.",
        ),
        ui.Spacer(1),
        common.line("Parent → X 2 / Y 1"),
        common.line("Child → X 3 / Y 2"),
        common.line("Badge → X 2 / Y 1"),
      ]),
    ]),
  ]
}

fn relative_chain() -> ui.Element {
  ui.Box(
    [
      ui.X(2),
      ui.Y(1),
      ui.Width(28),
      ui.Height(12),
      ui.Padding(1),
      ui.Background(common.color(common.accent_blue)),
      ui.Border("Parent + (2,1)", common.color(common.border_fg)),
    ],
    [
      ui.Box(
        [
          ui.X(3),
          ui.Y(2),
          ui.Width(18),
          ui.Height(6),
          ui.Padding(1),
          ui.Background(common.color(common.accent_green)),
          ui.Border("Child + (3,2)", common.color(common.border_fg)),
        ],
        [
          ui.Box(
            [
              ui.X(2),
              ui.Y(1),
              ui.Width(10),
              ui.Height(3),
              ui.Padding(0),
              ui.Background(common.color(common.accent_orange)),
              ui.Border("", common.color(common.border_fg)),
            ],
            [
              ui.Text(
                [
                  ui.X(1),
                  ui.Y(1),
                  ui.Foreground(common.color(common.bg_color)),
                  ui.Background(common.color(common.accent_orange)),
                  ui.Attributes(1),
                ],
                "Badge",
              ),
            ],
          ),
        ],
      ),
    ],
  )
}
