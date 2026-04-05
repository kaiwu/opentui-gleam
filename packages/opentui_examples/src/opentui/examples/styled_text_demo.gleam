import opentui/examples/common
import opentui/ui

pub fn main() -> Nil {
  common.run_static_ui_demo("Styled Text Demo", "Styled Text Demo", view())
}

fn view() -> List(ui.Element) {
  [
    common.panel("Text styles", 2, 3, 76, 18, [
      ui.Column([ui.Gap(1)], [
        common.line("Default foreground on the panel background."),
        common.line_with([ui.Attributes(1)], "Bold via terminal attributes."),
        common.line_with(
          [ui.Foreground(common.color(common.accent_blue))],
          "Accent foreground for navigational emphasis.",
        ),
        common.line_with(
          [
            ui.Foreground(common.color(common.bg_color)),
            ui.Background(common.color(common.accent_yellow)),
          ],
          "Inverted label style using a bright background.",
        ),
        common.line_with(
          [
            ui.Foreground(common.color(common.accent_green)),
            ui.Background(common.color(common.panel_bg)),
          ],
          "Semantic green for success states.",
        ),
        ui.Spacer(1),
        common.paragraph(
          "Phase 1 styling is intentionally simple: color, background, bold attributes, wrapping, and truncation already let the demos present meaningful hierarchy without bespoke widgets.",
        ),
      ]),
    ]),
  ]
}
