import gleam/io

pub type Demo {
  Demo(id: String, module: String, description: String)
}

pub fn demos() -> List(Demo) {
  [
    Demo(
      id: "editor",
      module: "opentui/examples/editor",
      description: "Interactive text editor demo built entirely in Gleam.",
    ),
    Demo(
      id: "terminal-title",
      module: "opentui/examples/terminal_title",
      description: "Terminal title demo ported from the TypeScript examples.",
    ),
    Demo(
      id: "text-wrap",
      module: "opentui/examples/text_wrap",
      description: "Pure Gleam word and character wrapping helpers visualized in a TUI.",
    ),
    Demo(
      id: "text-truncation",
      module: "opentui/examples/text_truncation",
      description: "Pure Gleam end and middle truncation helpers visualized in a TUI.",
    ),
  ]
}

pub fn print_demo_catalog() -> Nil {
  io.println(help_text())
}

pub fn help_text() -> String {
  "OpenTUI Gleam bindings\n\n"
  <> "This package exposes a growing Gleam-first demo ecosystem.\n"
  <> "Run demos directly with `gleam run -m <module>`.\n\n"
  <> "Available demos:\n"
  <> format_demos(demos())
  <> "\nPlace new demos under `src/opentui/examples/` and compose them from reusable `opentui/*` bindings."
}

fn format_demos(demos: List(Demo)) -> String {
  case demos {
    [] -> "  (none yet)\n"
    [Demo(id:, module:, description:)] ->
      "  - "
      <> id
      <> "\n"
      <> "    module: "
      <> module
      <> "\n"
      <> "    "
      <> description
      <> "\n"
    [Demo(id:, module:, description:), ..rest] ->
      "  - "
      <> id
      <> "\n"
      <> "    module: "
      <> module
      <> "\n"
      <> "    "
      <> description
      <> "\n"
      <> format_demos(rest)
  }
}
