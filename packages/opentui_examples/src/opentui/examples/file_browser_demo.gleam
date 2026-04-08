import gleam/int
import gleam/list
import opentui/examples/common
import opentui/examples/phase2_model as model
import opentui/examples/phase4_state as state
import opentui/interaction
import opentui/ui
import opentui/widgets

const file_count = 12

pub fn main() -> Nil {
  let focus = state.create_generic(interaction.focus_group(2))
  let sel = state.create_generic(widgets.select_state(file_count))
  let scroll = state.create_generic(
    widgets.scroll_state(10)
    |> widgets.set_content_height(list.length(file_content(0))),
  )

  common.run_interactive_ui_demo(
    "File Browser Demo",
    "File Browser Demo",
    fn(key) { handle_key(focus, sel, scroll, key) },
    fn() { view(focus, sel, scroll) },
  )
}

fn handle_key(
  focus: state.GenericCell,
  sel: state.GenericCell,
  scroll: state.GenericCell,
  raw: String,
) -> Nil {
  let fg: interaction.FocusGroup = state.get_generic(focus)
  let key = model.parse_key(raw)

  case key {
    model.Tab -> state.set_generic(focus, interaction.focus_next(fg))
    model.ShiftTab -> state.set_generic(focus, interaction.focus_prev(fg))
    _ ->
      case fg.focused {
        0 -> handle_file_list_key(sel, scroll, key)
        _ -> handle_preview_key(scroll, key)
      }
  }
}

fn handle_file_list_key(
  sel: state.GenericCell,
  scroll: state.GenericCell,
  key: model.Key,
) -> Nil {
  let s: widgets.SelectState = state.get_generic(sel)
  let new_s = case key {
    model.ArrowUp -> widgets.select_up(s)
    model.ArrowDown -> widgets.select_down(s)
    model.Home -> widgets.select_set(s, 0)
    model.End -> widgets.select_set(s, s.count - 1)
    _ -> s
  }
  state.set_generic(sel, new_s)
  let content_h = list.length(file_content(new_s.selected))
  let sc: widgets.ScrollState = state.get_generic(scroll)
  state.set_generic(
    scroll,
    widgets.set_content_height(widgets.scroll_to(sc, 0), content_h),
  )
}

fn handle_preview_key(scroll: state.GenericCell, key: model.Key) -> Nil {
  let sc: widgets.ScrollState = state.get_generic(scroll)
  let new_sc = case key {
    model.ArrowUp -> widgets.scroll_up(sc, 1)
    model.ArrowDown -> widgets.scroll_down(sc, 1)
    model.Home -> widgets.scroll_to(sc, 0)
    model.End -> widgets.scroll_to(sc, sc.content_height)
    _ -> sc
  }
  state.set_generic(scroll, new_sc)
}

fn view(
  focus: state.GenericCell,
  sel: state.GenericCell,
  scroll: state.GenericCell,
) -> List(ui.Element) {
  let fg: interaction.FocusGroup = state.get_generic(focus)
  let s: widgets.SelectState = state.get_generic(sel)
  let sc: widgets.ScrollState = state.get_generic(scroll)

  let file_list_bg = case interaction.is_focused(fg, 0) {
    True -> common.accent_blue
    False -> common.panel_bg
  }
  let preview_bg = case interaction.is_focused(fg, 1) {
    True -> common.accent_blue
    False -> common.panel_bg
  }

  let content = file_content(s.selected)
  let content_rows = list.map(content, fn(line) {
    common.line_with(
      [ui.Foreground(common.color(common.fg_color))],
      line,
    )
  })

  [
    common.panel_with_background(
      "Files",
      2,
      3,
      26,
      18,
      file_list_bg,
      [
        widgets.select_list(
          [ui.Gap(0)],
          s,
          file_names(),
          [ui.Foreground(common.color(common.fg_color))],
          [
            ui.Foreground(common.color(common.accent_green)),
            ui.Attributes(1),
          ],
        ),
      ],
    ),
    common.panel_with_background(
      file_name_at(s.selected),
      30,
      3,
      36,
      18,
      preview_bg,
      [widgets.scroll_view([], sc, content_rows)],
    ),
    common.panel("Info", 68, 3, 10, 18, [
      ui.Column([ui.Gap(1)], [
        common.line("Tab"),
        common.line(" pane"),
        common.line("↑↓"),
        common.line(" nav"),
        ui.Spacer(1),
        common.line_with(
          [ui.Foreground(common.color(common.muted_fg))],
          "L:" <> int.to_string(sc.offset + 1),
        ),
      ]),
    ]),
  ]
}

fn file_names() -> List(String) {
  [
    "README.md", "gleam.toml", "src/main.gleam", "src/router.gleam",
    "src/db.gleam", "src/auth.gleam", "test/main_test.gleam",
    "test/db_test.gleam", ".gitignore", "LICENSE", "CHANGELOG.md",
    "Makefile",
  ]
}

fn file_name_at(index: Int) -> String {
  case list.drop(file_names(), index) {
    [name, ..] -> name
    [] -> "unknown"
  }
}

fn file_content(index: Int) -> List(String) {
  case index {
    0 -> [
      "# My Project", "", "A Gleam web application.", "",
      "## Getting Started", "", "```sh", "gleam run", "```", "",
      "## Features", "- Routing", "- Database", "- Auth",
    ]
    1 -> [
      "name = \"my_project\"", "version = \"1.0.0\"",
      "gleam = \">= 1.15.0\"", "", "[dependencies]",
      "gleam_stdlib = \">= 0.44.0\"", "wisp = \">= 1.0.0\"",
    ]
    2 -> [
      "import gleam/io", "import router", "",
      "pub fn main() -> Nil {", "  io.println(\"Starting...\")",
      "  router.start()", "}", "",
    ]
    3 -> [
      "import wisp", "", "pub type Route {", "  Home", "  About",
      "  NotFound", "}", "", "pub fn start() -> Nil {",
      "  wisp.serve(handler, 8080)", "}", "",
      "fn handler(req) -> Response {", "  case route(req) {",
      "    Home -> home_page()", "    About -> about_page()",
      "    NotFound -> not_found()", "  }", "}",
    ]
    4 -> [
      "import sqlight", "", "pub type Db {", "  Db(conn: Connection)",
      "}", "", "pub fn connect() -> Db {",
      "  let conn = sqlight.open(\":memory:\")", "  Db(conn)", "}",
    ]
    5 -> [
      "import gleam/crypto", "", "pub fn hash(password: String) {",
      "  crypto.hash(Sha256, password)", "}", "",
      "pub fn verify(password, hash) {",
      "  hash(password) == hash", "}",
    ]
    6 -> [
      "import gleeunit", "import main", "",
      "pub fn main_test() -> Nil {", "  gleeunit.main()", "}",
    ]
    7 -> [
      "import gleeunit", "import db", "",
      "pub fn connect_test() -> Nil {", "  let d = db.connect()",
      "  // verify connection", "}", "",
    ]
    8 -> [
      "build/", "*.beam", "erl_crash.dump", ".env",
      "node_modules/",
    ]
    9 -> ["MIT License", "", "Copyright (c) 2026", "", "Permission is hereby granted..."]
    10 -> [
      "# Changelog", "", "## 1.0.0", "- Initial release",
      "- Router", "- Database", "- Auth", "", "## 0.1.0",
      "- Project scaffold",
    ]
    _ -> [
      "all: build test", "", "build:", "\tgleam build", "",
      "test:", "\tgleam test", "", "run:", "\tgleam run", "",
      "clean:", "\trm -rf build/",
    ]
  }
}
