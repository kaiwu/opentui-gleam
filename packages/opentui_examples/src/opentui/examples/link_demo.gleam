import opentui/examples/common
import opentui/ui

pub fn main() -> Nil {
  common.run_static_ui_demo("Link Demo", "Link Demo", view())
}

fn view() -> List(ui.Element) {
  [
    common.panel("Link-like text", 2, 3, 36, 18, [
      ui.Column([ui.Gap(1)], [
        link_line("https://opentui.dev/docs"),
        link_line("gitea://kaiwu/opentui-gleam"),
        link_line("run-example://simple-layout-example"),
        ui.Spacer(1),
        common.paragraph(
          "Phase 1 focuses on visual link treatment first: color, hierarchy, and clear destinations rendered as pure text nodes.",
        ),
      ]),
    ]),
    common.panel("Future pressure", 42, 3, 36, 18, [
      ui.Column([ui.Gap(1)], [
        common.line("Next layers can add:"),
        common.line("- hover state"),
        common.line("- focus metadata"),
        common.line("- activation callbacks"),
        ui.Spacer(1),
        common.paragraph(
          "The demo is now runnable today while still making the missing runtime capabilities explicit.",
        ),
      ]),
    ]),
  ]
}

fn link_line(content: String) -> ui.Element {
  common.line_with(
    [
      ui.Foreground(common.color(common.accent_blue)),
      ui.Attributes(1),
    ],
    content,
  )
}
