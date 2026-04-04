import gleam/string
import gleeunit
import gleeunit/should
import opentui/text
import opentui/ui

pub fn main() {
  gleeunit.main()
}

pub fn fold_counts_nested_elements_test() {
  let tree = [
    ui.Box(
      [
        ui.Width(10),
        ui.Height(5),
        ui.Padding(1),
        ui.Background(ui.Color(0.0, 0.0, 0.0, 1.0)),
      ],
      [
        ui.Column([ui.Gap(1)], [
          ui.Text(
            [
              ui.Foreground(ui.Color(1.0, 1.0, 1.0, 1.0)),
              ui.Background(ui.Color(0.0, 0.0, 0.0, 1.0)),
            ],
            "Hello",
          ),
        ]),
      ],
    ),
  ]

  ui.fold(tree, 0, fn(acc, _el) { acc + 1 })
  |> should.equal(3)
}

pub fn to_string_mentions_box_and_text_test() {
  let tree = [
    ui.Box(
      [
        ui.Width(10),
        ui.Height(5),
        ui.Padding(1),
        ui.Background(ui.Color(0.0, 0.0, 0.0, 1.0)),
      ],
      [
        ui.Text(
          [
            ui.Foreground(ui.Color(1.0, 1.0, 1.0, 1.0)),
            ui.Background(ui.Color(0.0, 0.0, 0.0, 1.0)),
          ],
          "Hello",
        ),
      ],
    ),
  ]

  let output = ui.to_string(tree)
  string.contains(output, "Box(") |> should.equal(True)
  string.contains(output, "Text(") |> should.equal(True)
  string.contains(output, "\"Hello\"") |> should.equal(True)
}

pub fn plan_resolves_box_rect_from_styles_test() {
  let nodes =
    ui.plan(
      [
        ui.Box(
          [ui.X(2), ui.Y(3), ui.Width(10), ui.Height(5), ui.Padding(1)],
          [],
        ),
      ],
      80,
      24,
    )

  nodes
  |> should.equal([ui.LayoutNode("Box", 2, 3, 10, 5, [])])
}

pub fn plan_column_stacks_children_with_gap_test() {
  let nodes =
    ui.plan(
      [
        ui.Column([ui.X(4), ui.Y(2), ui.Width(20), ui.Height(10), ui.Gap(2)], [
          ui.Text([], "One"),
          ui.Text([], "Two"),
        ]),
      ],
      80,
      24,
    )

  case nodes {
    [ui.LayoutNode("Column", 4, 2, 20, 10, children)] ->
      children
      |> should.equal([
        ui.LayoutNode("Text", 4, 2, 20, 1, []),
        ui.LayoutNode("Text", 4, 5, 20, 1, []),
      ])
    _ -> panic as "expected a column layout node"
  }
}

pub fn plan_paragraph_honors_max_lines_test() {
  let nodes =
    ui.plan(
      [
        ui.Paragraph(
          [ui.Width(10), ui.Height(8), ui.Wrap(text.WordWrap), ui.MaxLines(2)],
          "alpha beta gamma delta",
        ),
      ],
      80,
      24,
    )

  nodes
  |> should.equal([ui.LayoutNode("Paragraph", 0, 0, 10, 2, [])])
}
