import opentui/examples/common
import opentui/ui

pub fn main() -> Nil {
  common.run_static_ui_demo("Text Node Demo", "Text Node Demo", view())
}

fn view() -> List(ui.Element) {
  [
    common.panel("Text nodes", 2, 3, 36, 18, [
      ui.Column([ui.Gap(1)], [
        common.line_with([ui.Attributes(1)], "Text"),
        common.line("Single-line labels keep exact layout."),
        ui.Spacer(1),
        common.line_with([ui.Attributes(1)], "Paragraph"),
        common.paragraph(
          "Paragraph nodes wrap automatically and are better for descriptive copy or explanatory documentation.",
        ),
      ]),
    ]),
    common.panel("Mixed composition", 42, 3, 36, 18, [
      ui.Column([ui.Gap(1)], [
        common.line_with([ui.Attributes(1)], "Release summary"),
        common.paragraph(
          "Text nodes become richer screens when a heading, body copy, and status lines are assembled into one column.",
        ),
        common.line_with(
          [ui.Foreground(common.color(common.accent_green))],
          "status: rendered",
        ),
        common.line_with(
          [ui.Foreground(common.color(common.accent_blue))],
          "module: opentui/examples/text_node_demo",
        ),
      ]),
    ]),
  ]
}
