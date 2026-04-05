import opentui/examples/common
import opentui/ui

pub fn main() -> Nil {
  common.run_static_ui_demo("Fonts Demo", "Fonts Demo", view())
}

fn view() -> List(ui.Element) {
  [
    common.panel("ASCII title", 2, 3, 40, 18, [
      ui.Column([ui.Gap(0)], [
        banner_line("  ___                 _       _ "),
        banner_line(" / _ \\ _ __   ___ _ __| |_ ___| |"),
        banner_line("| | | | '_ \\ / _ \\ '__| __/ _ \\ |"),
        banner_line("| |_| | |_) |  __/ |  | ||  __/ |"),
        banner_line(" \\___/| .__/ \\___|_|   \\__\\___|_|"),
        banner_line("      |_|                           "),
        ui.Spacer(1),
        common.paragraph(
          "Phase 1 does not have font loading yet, but plain text nodes already support banner-style typography for headings and splash screens.",
        ),
      ]),
    ]),
    common.panel("Density study", 46, 3, 32, 18, [
      ui.Column([ui.Gap(1)], [
        common.line_with([ui.Attributes(1)], "small: opentui"),
        common.line_with(
          [ui.Foreground(common.color(common.accent_blue))],
          "medium: O P E N T U I",
        ),
        common.line_with(
          [ui.Foreground(common.color(common.accent_green))],
          "wide: [ OPEN ][ TUI ]",
        ),
        common.line_with(
          [
            ui.Foreground(common.color(common.bg_color)),
            ui.Background(common.color(common.accent_yellow)),
          ],
          "badge: DEMO",
        ),
      ]),
    ]),
  ]
}

fn banner_line(content: String) -> ui.Element {
  common.line_with(
    [
      ui.Foreground(common.color(common.accent_green)),
      ui.Attributes(1),
    ],
    content,
  )
}
