import gleam/string
import gleeunit
import gleeunit/should
import opentui/draw_plan
import opentui/interaction
import opentui/text
import opentui/ui

pub fn main() {
  gleeunit.main()
}

pub fn draw_plan_append_and_count_test() {
  []
  |> draw_plan.append(draw_plan.fill_rect(
    1,
    2,
    3,
    4,
    draw_plan.Color(0.1, 0.2, 0.3, 1.0),
  ))
  |> draw_plan.append(draw_plan.text(
    3,
    4,
    "hi",
    draw_plan.Color(1.0, 1.0, 1.0, 1.0),
    draw_plan.Color(0.0, 0.0, 0.0, 0.0),
    0,
  ))
  |> draw_plan.op_count
  |> should.equal(2)
}

pub fn draw_plan_concat_preserves_order_test() {
  let plan =
    draw_plan.concat([
      [
        draw_plan.cell(
          1,
          1,
          65,
          draw_plan.Color(1.0, 0.0, 0.0, 1.0),
          draw_plan.Color(0.0, 0.0, 0.0, 0.0),
          0,
        ),
      ],
      [
        draw_plan.text(
          2,
          2,
          "ok",
          draw_plan.Color(1.0, 1.0, 1.0, 1.0),
          draw_plan.Color(0.0, 0.0, 0.0, 0.0),
          0,
        ),
      ],
    ])

  plan
  |> should.equal([
    draw_plan.Cell(
      1,
      1,
      65,
      draw_plan.Color(1.0, 0.0, 0.0, 1.0),
      draw_plan.Color(0.0, 0.0, 0.0, 0.0),
      0,
    ),
    draw_plan.Text(
      2,
      2,
      "ok",
      draw_plan.Color(1.0, 1.0, 1.0, 1.0),
      draw_plan.Color(0.0, 0.0, 0.0, 0.0),
      0,
    ),
  ])
}

pub fn draw_plan_map_updates_cells_test() {
  [
    draw_plan.cell(
      4,
      5,
      42,
      draw_plan.Color(0.2, 0.4, 0.6, 1.0),
      draw_plan.Color(0.0, 0.0, 0.0, 0.0),
      0,
    ),
  ]
  |> draw_plan.map(fn(op) {
    case op {
      draw_plan.Cell(x, y, codepoint, fg, bg, attrs) ->
        draw_plan.Cell(x + 1, y + 2, codepoint, fg, bg, attrs)
      other -> other
    }
  })
  |> should.equal([
    draw_plan.Cell(
      5,
      7,
      42,
      draw_plan.Color(0.2, 0.4, 0.6, 1.0),
      draw_plan.Color(0.0, 0.0, 0.0, 0.0),
      0,
    ),
  ])
}

pub fn interaction_hit_test_accepts_inside_points_test() {
  interaction.hit_test(interaction.region(10, 5, 8, 4), 12, 7)
  |> should.equal(True)
}

pub fn interaction_begin_drag_captures_offsets_test() {
  let session =
    interaction.begin_drag(
      interaction.idle_drag(),
      interaction.region(18, 6, 44, 13),
      20,
      9,
    )

  session
  |> should.equal(interaction.DragSession(True, 2, 3))
}

pub fn interaction_drag_to_returns_clamped_position_test() {
  let session = interaction.DragSession(True, 2, 3)

  interaction.drag_to(session, interaction.bounds(0, 4, 36, 11), 999, 999)
  |> should.equal(interaction.DragRegion(36, 11, 0, 0))
}

pub fn interaction_clamp_region_preserves_size_test() {
  interaction.clamp_region(
    interaction.region(50, 20, 30, 12),
    interaction.bounds(0, 4, 36, 11),
  )
  |> should.equal(interaction.DragRegion(36, 11, 30, 12))
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

// --- New tests ---

pub fn plan_spacer_uses_given_height_test() {
  let nodes = ui.plan([ui.Spacer(3)], 80, 24)

  nodes
  |> should.equal([ui.LayoutNode("Spacer", 0, 0, 80, 3, [])])
}

pub fn plan_box_with_border_nests_children_inside_test() {
  let nodes =
    ui.plan(
      [
        ui.Box(
          [
            ui.Width(20),
            ui.Height(10),
            ui.Border("Title", ui.Color(1.0, 1.0, 1.0, 1.0)),
          ],
          [ui.Text([], "Inner")],
        ),
      ],
      80,
      24,
    )

  case nodes {
    [ui.LayoutNode("Box", 0, 0, 20, 10, [child])] -> {
      let _ = child.kind |> should.equal("Text")
      let _ = child.x |> should.equal(1)
      child.y |> should.equal(1)
    }
    _ -> panic as "expected box with one child"
  }
}

pub fn plan_box_with_border_and_padding_test() {
  let nodes =
    ui.plan(
      [
        ui.Box(
          [
            ui.Width(20),
            ui.Height(10),
            ui.Border("T", ui.Color(1.0, 1.0, 1.0, 1.0)),
            ui.Padding(2),
          ],
          [ui.Text([], "Deep")],
        ),
      ],
      80,
      24,
    )

  case nodes {
    [ui.LayoutNode("Box", 0, 0, 20, 10, [child])] -> {
      let _ = child.x |> should.equal(3)
      child.y |> should.equal(3)
    }
    _ -> panic as "expected box with one child"
  }
}

pub fn plan_empty_children_test() {
  let nodes = ui.plan([ui.Column([ui.Width(10), ui.Height(5)], [])], 80, 24)

  nodes
  |> should.equal([ui.LayoutNode("Column", 0, 0, 10, 5, [])])
}

pub fn plan_paragraph_wraps_to_natural_height_test() {
  let nodes =
    ui.plan(
      [
        ui.Paragraph(
          [ui.Width(10), ui.Height(20), ui.Wrap(text.WordWrap)],
          "alpha beta gamma delta",
        ),
      ],
      80,
      24,
    )

  case nodes {
    [ui.LayoutNode("Paragraph", 0, 0, 10, h, [])] ->
      { h > 1 } |> should.equal(True)
    _ -> panic as "expected paragraph node"
  }
}

pub fn plan_nested_box_in_column_test() {
  let nodes =
    ui.plan(
      [
        ui.Column([ui.Width(40), ui.Height(20)], [
          ui.Text([], "Header"),
          ui.Box([ui.Width(30), ui.Height(8)], [
            ui.Text([], "Nested"),
          ]),
        ]),
      ],
      80,
      24,
    )

  case nodes {
    [ui.LayoutNode("Column", 0, 0, 40, 20, [text_node, box_node])] -> {
      let _ = text_node.kind |> should.equal("Text")
      let _ = text_node.y |> should.equal(0)
      let _ = box_node.kind |> should.equal("Box")
      box_node.y |> should.equal(1)
    }
    _ -> panic as "expected column with text and box"
  }
}

pub fn plan_text_defaults_to_parent_width_test() {
  let nodes = ui.plan([ui.Text([], "hello")], 80, 24)

  nodes
  |> should.equal([ui.LayoutNode("Text", 0, 0, 80, 1, [])])
}

pub fn fold_visits_spacer_test() {
  let tree = [ui.Spacer(2), ui.Text([], "a")]
  ui.fold(tree, 0, fn(acc, _el) { acc + 1 })
  |> should.equal(2)
}

pub fn to_string_shows_spacer_height_test() {
  let output = ui.to_string([ui.Spacer(5)])
  string.contains(output, "Spacer(5)") |> should.equal(True)
}

pub fn to_string_truncates_long_paragraph_test() {
  let output =
    ui.to_string([
      ui.Paragraph(
        [],
        "this is a very long paragraph that should be truncated in the debug output",
      ),
    ])
  string.contains(output, "Paragraph(") |> should.equal(True)
  string.contains(output, "…") |> should.equal(True)
}

pub fn fold_deep_nesting_test() {
  let tree = [
    ui.Box([], [
      ui.Box([], [
        ui.Box([], [ui.Text([], "deep")]),
      ]),
    ]),
  ]
  ui.fold(tree, 0, fn(acc, _el) { acc + 1 })
  |> should.equal(4)
}

pub fn plan_column_single_child_no_gap_test() {
  let nodes =
    ui.plan(
      [ui.Column([ui.Width(20), ui.Height(10), ui.Gap(3)], [ui.Text([], "x")])],
      80,
      24,
    )

  case nodes {
    [ui.LayoutNode("Column", _, _, _, _, [child])] ->
      child |> should.equal(ui.LayoutNode("Text", 0, 0, 20, 1, []))
    _ -> panic as "expected column with single child"
  }
}
