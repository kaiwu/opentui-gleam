import gleam/list
import gleam/string
import opentui/examples/common
import opentui/examples/phase2_model
import opentui/examples/phase2_state as state
import opentui/examples/phase3_model as model
import opentui/ui

pub fn main() -> Nil {
  let scroll = state.create_int(0)

  common.run_interactive_ui_demo(
    "Markdown Demo",
    "Markdown Demo",
    fn(key) {
      let k = phase2_model.parse_key(key)
      state.set_int(
        scroll,
        phase2_model.adjust_scroll(state.get_int(scroll), k, 20),
      )
    },
    fn() { view(scroll) },
  )
}

fn view(scroll: state.IntCell) -> List(ui.Element) {
  let offset = state.get_int(scroll)
  let blocks = model.parse_markdown_blocks(sample_markdown())
  let elements = list.flat_map(blocks, block_to_elements)
  let visible = visible_elements(elements, offset, 14)

  [
    common.panel("Rendered Markdown", 2, 3, 54, 18, [
      ui.Column([ui.Gap(0)], visible),
    ]),
    common.panel("Info", 58, 3, 20, 18, [
      ui.Column([ui.Gap(1)], [
        common.line("Blocks: " <> block_count(blocks)),
        common.line("Offset: " <> scroll_label(offset)),
        ui.Spacer(1),
        common.line("Up/Down scroll"),
        ui.Spacer(1),
        common.paragraph(
          "Markdown parsed into MdBlock ADT, then transformed into Element tree. Pure FP — no native markdown engine.",
        ),
      ]),
    ]),
  ]
}

fn block_to_elements(block: model.MdBlock) -> List(ui.Element) {
  case block {
    model.MdHeading(level, text) -> [
      ui.Spacer(1),
      common.line_with(
        [
          ui.Foreground(common.color(heading_color(level))),
          ui.Attributes(1),
        ],
        string.repeat("#", level) <> " " <> text,
      ),
    ]
    model.MdParagraph(text) -> [ui.Spacer(1), common.paragraph(text)]
    model.MdCodeBlock(_lang, code) -> {
      let lines = string.split(code, "\n")
      [
        ui.Spacer(1),
        ..list.map(lines, fn(line) {
          common.line_with(
            [
              ui.Foreground(common.color(common.accent_green)),
              ui.Background(common.color(#(0.03, 0.05, 0.08, 1.0))),
            ],
            "  " <> line,
          )
        })
      ]
    }
    model.MdBulletList(items) -> [
      ui.Spacer(1),
      ..list.map(items, fn(item) { common.line("  • " <> item) })
    ]
    model.MdHRule -> [
      ui.Spacer(1),
      common.line_with(
        [ui.Foreground(common.color(common.border_fg))],
        "────────────────────────────────────────────",
      ),
    ]
  }
}

fn heading_color(level: Int) -> #(Float, Float, Float, Float) {
  case level {
    1 -> common.accent_blue
    2 -> common.accent_green
    _ -> common.accent_yellow
  }
}

fn visible_elements(
  elements: List(ui.Element),
  offset: Int,
  count: Int,
) -> List(ui.Element) {
  elements
  |> list.drop(offset)
  |> list.take(count)
}

fn block_count(blocks: List(model.MdBlock)) -> String {
  case list.length(blocks) {
    n -> int_label(n)
  }
}

fn scroll_label(n: Int) -> String {
  int_label(n)
}

fn int_label(n: Int) -> String {
  case n {
    0 -> "0"
    1 -> "1"
    2 -> "2"
    3 -> "3"
    4 -> "4"
    5 -> "5"
    6 -> "6"
    7 -> "7"
    8 -> "8"
    9 -> "9"
    _ -> "10+"
  }
}

fn sample_markdown() -> String {
  "# OpenTUI Gleam

A functional TUI framework built on composable data.

## Core Idea

Every screen is a pure function of state:

```gleam
fn view(state) -> List(Element)
```

## Features

- Algebraic data types for UI elements
- Pure rendering — no reconciler
- Composable style system
- Pattern matching on element trees

---

## Why Gleam?

Gleam gives correctness guarantees that matter for TUIs:

- Exhaustive case analysis
- No null or undefined
- Immutability by default

### Getting Started

Install the package and run the demos:

```bash
gleam run -m opentui/examples/catalog
```

- Try the editor demo
- Explore the table formatter
- Check out syntax highlighting"
}
