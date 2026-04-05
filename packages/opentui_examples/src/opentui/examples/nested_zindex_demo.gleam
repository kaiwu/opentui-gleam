import opentui/examples/common
import opentui/ui

pub fn main() -> Nil {
  common.run_static_ui_demo(
    "Nested Z-Index Demo",
    "Nested Z-Index Demo",
    view(),
  )
}

fn view() -> List(ui.Element) {
  [
    common.panel("Canvas", 2, 3, 48, 18, [
      common.paragraph(
        "Later siblings paint on top of earlier siblings. These overlapping cards are separate elements rendered in order.",
      ),
    ]),
    layer("Layer 1", 8, 8, 24, 8, common.accent_blue),
    layer("Layer 2", 18, 10, 24, 8, common.accent_green),
    layer("Layer 3", 28, 12, 18, 6, common.accent_pink),
    common.panel("Stack order", 54, 3, 24, 18, [
      ui.Column([ui.Gap(1)], [
        common.line("1. canvas background"),
        common.line("2. layer 1"),
        common.line("3. layer 2"),
        common.line_with(
          [ui.Foreground(common.color(common.accent_pink))],
          "4. layer 3 (topmost)",
        ),
        ui.Spacer(1),
        common.paragraph(
          "That gives a practical Phase 1 layering story even before a richer z-index API exists.",
        ),
      ]),
    ]),
  ]
}

fn layer(
  title: String,
  x: Int,
  y: Int,
  w: Int,
  h: Int,
  bg: #(Float, Float, Float, Float),
) -> ui.Element {
  common.panel_with_background(title, x, y, w, h, bg, [
    ui.Column([ui.Gap(1)], [
      ui.Text(
        [
          ui.Foreground(common.color(common.bg_color)),
          ui.Background(common.color(bg)),
          ui.Attributes(1),
        ],
        "Rendered later = visually higher",
      ),
    ]),
  ])
}
