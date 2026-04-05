import opentui/examples/common
import opentui/ui

pub fn main() -> Nil {
  common.run_static_ui_demo(
    "VNode Composition Demo",
    "VNode Composition Demo",
    view(),
  )
}

pub fn view() -> List(ui.Element) {
  [
    common.panel("Composition", 2, 3, 76, 7, [
      ui.Column([ui.Gap(1)], [
        common.line_with(
          [ui.Attributes(1)],
          "Small pure functions assemble the full screen.",
        ),
        common.paragraph(
          "This demo builds badges, cards, and summaries separately and then returns one merged element list for the renderer.",
        ),
      ]),
    ]),
    metric_card("Builds", "24", 2, 12, common.accent_blue),
    metric_card("Tests", "18", 22, 12, common.accent_green),
    metric_card("Docs", "3", 42, 12, common.accent_orange),
    metric_card("Demos", "11", 62, 12, common.accent_pink),
    common.panel("Composed footer", 2, 19, 76, 2, [
      ui.Text(
        [
          ui.Foreground(common.color(common.muted_fg)),
          ui.Background(common.color(common.panel_bg)),
        ],
        "metric_card + summary_panel + badges -> final UI tree",
      ),
    ]),
  ]
}

fn metric_card(
  title: String,
  value: String,
  x: Int,
  y: Int,
  bg: #(Float, Float, Float, Float),
) -> ui.Element {
  common.panel_with_background(title, x, y, 16, 6, bg, [
    ui.Column([ui.Gap(1)], [
      ui.Text(
        [
          ui.Foreground(common.color(common.bg_color)),
          ui.Background(common.color(bg)),
        ],
        "pure value",
      ),
      ui.Text(
        [
          ui.Foreground(common.color(common.bg_color)),
          ui.Background(common.color(bg)),
          ui.Attributes(1),
        ],
        value,
      ),
    ]),
  ])
}
