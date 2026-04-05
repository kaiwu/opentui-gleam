import gleam/list
import gleam/string
import gleeunit/should
import opentui/examples/relative_positioning_demo
import opentui/examples/simple_layout_example
import opentui/examples/vnode_composition_demo
import opentui/ui

pub fn simple_layout_example_has_expected_top_level_panels_test() {
  let planned = ui.plan(simple_layout_example.view(), 80, 24)

  let _ = list.length(planned) |> should.equal(4)

  case planned {
    [
      ui.LayoutNode("Box", 2, 3, 18, 18, _),
      ui.LayoutNode("Box", 22, 3, 56, 11, _),
      ui.LayoutNode("Box", 22, 15, 27, 6, _),
      ui.LayoutNode("Box", 51, 15, 27, 6, _),
    ] -> Nil
    _ ->
      panic as "simple_layout_example should keep its four-panel dashboard layout"
  }
}

pub fn relative_positioning_demo_plans_nested_offsets_test() {
  let planned = ui.plan(relative_positioning_demo.view(), 80, 24)

  case planned {
    [
      ui.LayoutNode(
        "Box",
        2,
        3,
        36,
        18,
        [
          ui.LayoutNode(
            "Box",
            6,
            6,
            28,
            12,
            [
              ui.LayoutNode(
                "Box",
                11,
                10,
                18,
                6,
                [
                  ui.LayoutNode(
                    "Box",
                    15,
                    13,
                    10,
                    3,
                    [ui.LayoutNode("Text", 17, 15, 7, 0, [])],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      _,
    ] -> Nil
    _ ->
      panic as "relative_positioning_demo should preserve parent-relative nested offsets"
  }
}

pub fn vnode_composition_demo_composes_expected_text_content_test() {
  let view = vnode_composition_demo.view()
  let rendered = ui.to_string(view)
  let text_count =
    ui.fold(view, 0, fn(count, element) {
      case element {
        ui.Text(_, _) -> count + 1
        _ -> count
      }
    })

  let _ = list.length(view) |> should.equal(6)
  let _ = text_count |> should.equal(10)
  let _ = string.contains(rendered, "Builds") |> should.equal(True)
  let _ = string.contains(rendered, "Demos") |> should.equal(True)
  string.contains(rendered, "metric_card + summary_panel + badges")
  |> should.equal(True)
}
