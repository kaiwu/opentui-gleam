import opentui/examples/common
import opentui/ui

pub fn main() -> Nil {
  common.run_static_ui_demo(
    "Simple Layout Example",
    "Simple Layout Example",
    view(),
  )
}

pub fn view() -> List(ui.Element) {
  [
    common.panel("Sidebar", 2, 3, 18, 18, [
      ui.Column([ui.Gap(1)], [
        common.line_with([ui.Attributes(1)], "Project"),
        common.paragraph("Phase 1 demos now render as real UI trees."),
        common.line("- renderer"),
        common.line("- buffer"),
        common.line("- ui"),
        ui.Spacer(1),
        common.line_with(
          [ui.Foreground(common.color(common.accent_green))],
          "Ready",
        ),
      ]),
    ]),
    common.panel("Workspace", 22, 3, 56, 11, [
      ui.Column([ui.Gap(1)], [
        common.line_with(
          [ui.Attributes(1)],
          "Layout primitives working together",
        ),
        common.paragraph(
          "This view uses three separate panels with fixed coordinates to create a dashboard-style layout without imperative drawing code.",
        ),
        common.paragraph(
          "The examples package can now demonstrate boxes, columns, padding, gaps, borders, and styled text as reusable data.",
        ),
      ]),
    ]),
    common.panel("Activity", 22, 15, 27, 6, [
      ui.Column([ui.Gap(1)], [
        common.line("compile examples"),
        common.line("render layout tree"),
        common.line("ship demo catalog"),
      ]),
    ]),
    common.panel("Notes", 51, 15, 27, 6, [
      ui.Column([ui.Gap(1)], [
        common.line_with(
          [ui.Foreground(common.color(common.accent_yellow))],
          "Composable",
        ),
        common.line("Panels are just UI values."),
        common.line("Rendering stays a final pass."),
      ]),
    ]),
  ]
}
