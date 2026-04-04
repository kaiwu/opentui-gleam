import gleam/string
import gleeunit
import gleeunit/should
import opentui/ui

pub fn main() {
  gleeunit.main()
}

pub fn fold_counts_nested_elements_test() {
  let tree = [
    ui.Box(
      ui.BoxProps(0, 0, 10, 5, 1, ui.Color(0.0, 0.0, 0.0, 1.0), ui.NoBorder),
      [
        ui.Column(ui.ColumnProps(1), [
          ui.Text(
            ui.TextProps(
              ui.Color(1.0, 1.0, 1.0, 1.0),
              ui.Color(0.0, 0.0, 0.0, 1.0),
              0,
            ),
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
      ui.BoxProps(0, 0, 10, 5, 1, ui.Color(0.0, 0.0, 0.0, 1.0), ui.NoBorder),
      [
        ui.Text(
          ui.TextProps(
            ui.Color(1.0, 1.0, 1.0, 1.0),
            ui.Color(0.0, 0.0, 0.0, 1.0),
            0,
          ),
          "Hello",
        ),
      ],
    ),
  ]

  let output = ui.to_string(tree)
  string.contains(output, "Box(") |> should.equal(True)
  string.contains(output, "Text(\"Hello\")") |> should.equal(True)
}
