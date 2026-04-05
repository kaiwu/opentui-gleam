import opentui/examples/common
import opentui/ui

pub fn main() -> Nil {
  common.run_static_ui_demo("Terminal Demo", "Terminal Demo", view())
}

fn view() -> List(ui.Element) {
  [
    common.panel("Runtime summary", 2, 3, 32, 18, [
      ui.Column([ui.Gap(1)], [
        common.line_with([ui.Attributes(1)], "Renderer state"),
        common.line("screen: alternate"),
        common.line("mouse: disabled"),
        common.line("size: 80 x 24"),
        ui.Spacer(1),
        common.paragraph(
          "This foundation demo turns the current renderer configuration into a small terminal dashboard.",
        ),
      ]),
    ]),
    swatch("Blue", 40, 4, common.accent_blue),
    swatch("Green", 54, 4, common.accent_green),
    swatch("Orange", 68, 4, common.accent_orange),
    swatch("Pink", 40, 10, common.accent_pink),
    swatch("Yellow", 54, 10, common.accent_yellow),
    swatch("Panel", 68, 10, common.panel_bg),
    common.panel("Palette", 36, 16, 42, 5, [
      ui.Column([ui.Gap(1)], [
        common.line_with([ui.Attributes(1)], "Terminal colors are just data."),
        common.paragraph(
          "That makes palette exploration and future capability reporting easy to compose into other demos.",
        ),
      ]),
    ]),
  ]
}

fn swatch(
  title: String,
  x: Int,
  y: Int,
  bg: #(Float, Float, Float, Float),
) -> ui.Element {
  common.panel_with_background(title, x, y, 12, 5, bg, [
    ui.Text(
      [
        ui.Foreground(common.color(common.bg_color)),
        ui.Background(common.color(bg)),
        ui.Attributes(1),
      ],
      "sample",
    ),
  ])
}
