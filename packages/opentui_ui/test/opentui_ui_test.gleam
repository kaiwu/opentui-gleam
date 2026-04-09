import gleam/string
import gleeunit
import gleeunit/should
import opentui/draw_plan
import opentui/frame_playback
import opentui/interaction
import opentui/simulation
import opentui/text
import opentui/timeline
import opentui/ui
import opentui/widgets

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

pub fn timeline_tick_below_period_has_no_firings_test() {
  let result = timeline.tick(timeline.every(800.0), 300.0)
  result
  |> should.equal(timeline.TickResult(timeline.Interval(True, 800.0, 300.0), 0))
}

pub fn timeline_tick_over_period_counts_firings_test() {
  let result = timeline.tick(timeline.every(800.0), 1700.0)
  result
  |> should.equal(timeline.TickResult(timeline.Interval(True, 800.0, 100.0), 2))
}

pub fn timeline_paused_tick_does_nothing_test() {
  let result = timeline.tick(timeline.pause(timeline.every(800.0)), 1700.0)
  result
  |> should.equal(timeline.TickResult(timeline.Interval(False, 800.0, 0.0), 0))
}

pub fn timeline_toggle_flips_enabled_state_test() {
  timeline.every(500.0)
  |> timeline.toggle
  |> timeline.is_enabled
  |> should.equal(False)
}

pub fn timeline_reset_clears_elapsed_test() {
  let timeline.TickResult(interval, _) =
    timeline.tick(timeline.every(500.0), 300.0)
  timeline.reset(interval)
  |> should.equal(timeline.Interval(True, 500.0, 0.0))
}

pub fn simulation_tick_fires_when_enabled_and_running_test() {
  simulation.tick(simulation.create(timeline.every(800.0)), 1700.0)
  |> should.equal(simulation.TickResult(
    simulation.AutoState(True, False, timeline.Interval(True, 800.0, 100.0)),
    2,
  ))
}

pub fn simulation_tick_paused_has_no_firings_test() {
  simulation.create(timeline.every(800.0))
  |> simulation.toggle_paused
  |> fn(state) { simulation.tick(state, 1700.0) }
  |> should.equal(simulation.TickResult(
    simulation.AutoState(True, True, timeline.Interval(True, 800.0, 0.0)),
    0,
  ))
}

pub fn simulation_disabled_tick_resets_interval_test() {
  let simulation.TickResult(state, _) =
    simulation.tick(simulation.create(timeline.every(800.0)), 300.0)

  state
  |> simulation.toggle_enabled
  |> fn(disabled) { simulation.tick(disabled, 1700.0) }
  |> should.equal(simulation.TickResult(
    simulation.AutoState(False, False, timeline.Interval(True, 800.0, 0.0)),
    0,
  ))
}

pub fn simulation_reset_interval_clears_elapsed_test() {
  let simulation.TickResult(state, _) =
    simulation.tick(simulation.create(timeline.every(800.0)), 300.0)

  state
  |> simulation.reset_interval
  |> should.equal(simulation.AutoState(
    True,
    False,
    timeline.Interval(True, 800.0, 0.0),
  ))
}

pub fn frame_playback_tick_advances_when_running_test() {
  frame_playback.create(4, 200.0)
  |> frame_playback.tick(150.0)
  |> should.equal(frame_playback.Playback(True, 150.0, 200.0, 4))
}

pub fn frame_playback_tick_stops_when_paused_test() {
  frame_playback.create(4, 200.0)
  |> frame_playback.pause
  |> frame_playback.tick(150.0)
  |> should.equal(frame_playback.Playback(False, 0.0, 200.0, 4))
}

pub fn frame_playback_current_frame_wraps_test() {
  frame_playback.create(4, 200.0)
  |> frame_playback.tick(800.0)
  |> frame_playback.current_frame
  |> should.equal(0)
}

pub fn frame_playback_speed_controls_clamp_test() {
  let faster =
    frame_playback.create(4, 50.0)
    |> frame_playback.increase_speed

  let slower =
    frame_playback.create(4, 2000.0)
    |> frame_playback.decrease_speed

  let _ = faster |> should.equal(frame_playback.Playback(True, 0.0, 50.0, 4))
  slower |> should.equal(frame_playback.Playback(True, 0.0, 2000.0, 4))
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

// ── Row layout tests ──

pub fn plan_row_places_children_horizontally_test() {
  let nodes =
    ui.plan(
      [
        ui.Row([ui.Width(40), ui.Height(5)], [
          ui.Text([ui.Width(10)], "A"),
          ui.Text([ui.Width(15)], "B"),
        ]),
      ],
      80,
      24,
    )

  case nodes {
    [ui.LayoutNode("Row", 0, 0, 40, 5, [a, b])] -> {
      let _ = a |> should.equal(ui.LayoutNode("Text", 0, 0, 10, 1, []))
      b |> should.equal(ui.LayoutNode("Text", 10, 0, 15, 1, []))
    }
    _ -> panic as "expected row with two children"
  }
}

pub fn plan_row_with_gap_test() {
  let nodes =
    ui.plan(
      [
        ui.Row([ui.Width(40), ui.Height(5), ui.Gap(2)], [
          ui.Text([ui.Width(8)], "A"),
          ui.Text([ui.Width(8)], "B"),
          ui.Text([ui.Width(8)], "C"),
        ]),
      ],
      80,
      24,
    )

  case nodes {
    [ui.LayoutNode("Row", 0, 0, 40, 5, [a, b, c])] -> {
      let _ = a.x |> should.equal(0)
      let _ = b.x |> should.equal(10)
      c.x |> should.equal(20)
    }
    _ -> panic as "expected row with three children"
  }
}

pub fn fold_counts_row_children_test() {
  let tree = [
    ui.Row([], [ui.Text([], "a"), ui.Text([], "b")]),
  ]
  ui.fold(tree, 0, fn(acc, _el) { acc + 1 })
  |> should.equal(3)
}

pub fn to_string_shows_row_test() {
  let output = ui.to_string([ui.Row([], [ui.Text([], "x")])])
  string.contains(output, "Row(") |> should.equal(True)
}

// ── Widget tests: ScrollState ──

pub fn scroll_state_initial_test() {
  let state = widgets.scroll_state(10)
  let _ = state.offset |> should.equal(0)
  state.viewport_height |> should.equal(10)
}

pub fn scroll_down_clamps_to_max_test() {
  widgets.scroll_state(5)
  |> widgets.set_content_height(8)
  |> widgets.scroll_down(100)
  |> fn(s) { s.offset }
  |> should.equal(3)
}

pub fn scroll_up_clamps_to_zero_test() {
  widgets.scroll_state(5)
  |> widgets.set_content_height(20)
  |> widgets.scroll_down(5)
  |> widgets.scroll_up(100)
  |> fn(s) { s.offset }
  |> should.equal(0)
}

pub fn scroll_view_applies_viewport_height_test() {
  let element =
    widgets.scroll_view([], widgets.scroll_state(4), [
      ui.Text([], "a"),
      ui.Text([], "b"),
    ])

  case element {
    ui.Column(styles, children) -> {
      let _ = styles |> should.equal([ui.Height(4)])
      children |> should.equal([ui.Text([], "a"), ui.Text([], "b")])
    }
    _ -> panic as "expected Column"
  }
}

// ── Widget tests: InputState ──

pub fn input_insert_test() {
  let state = widgets.input_state("hello")
  let updated = widgets.input_insert(state, "!")
  updated.value |> should.equal("hello!")
}

pub fn input_delete_backward_test() {
  let state = widgets.input_state("abc")
  let updated = widgets.input_delete_backward(state)
  updated.value |> should.equal("ab")
}

pub fn input_move_left_and_right_test() {
  let state = widgets.input_state("abc")
  let moved = widgets.input_move_left(state)
  let _ = moved.cursor |> should.equal(2)
  let back = widgets.input_move_right(moved)
  back.cursor |> should.equal(3)
}

pub fn input_home_end_test() {
  let state = widgets.input_state("hello")
  let home = widgets.input_move_home(state)
  let _ = home.cursor |> should.equal(0)
  let end = widgets.input_move_end(home)
  end.cursor |> should.equal(5)
}

pub fn input_insert_at_middle_test() {
  let state = widgets.InputState(value: "abcd", cursor: 2, focused: True)
  let updated = widgets.input_insert(state, "X")
  let _ = updated.value |> should.equal("abXcd")
  updated.cursor |> should.equal(3)
}

pub fn input_display_value_shows_cursor_when_focused_test() {
  widgets.InputState(value: "abc", cursor: 1, focused: True)
  |> widgets.input_display_value
  |> should.equal("a█bc")
}

pub fn input_display_value_uses_space_when_blurred_test() {
  widgets.InputState(value: "abc", cursor: 1, focused: False)
  |> widgets.input_display_value
  |> should.equal("a bc")
}

pub fn input_focus_and_blur_toggle_focus_test() {
  let state =
    widgets.input_state("x") |> widgets.input_blur |> widgets.input_focus
  state.focused |> should.equal(True)
}

pub fn text_input_renders_display_value_test() {
  case
    widgets.text_input(
      [],
      widgets.InputState(value: "abc", cursor: 2, focused: True),
    )
  {
    ui.Text(_, content) -> content |> should.equal("ab█c")
    _ -> panic as "expected Text"
  }
}

pub fn progress_bar_renders_filled_and_empty_cells_test() {
  case widgets.progress_bar([], 10, 0.4, "█", "░") {
    ui.Text(_, content) -> content |> should.equal("████░░░░░░")
    _ -> panic as "expected Text"
  }
}

pub fn progress_bar_clamps_progress_test() {
  case widgets.progress_bar([], 5, 2.0, "#", "-") {
    ui.Text(_, content) -> content |> should.equal("#####")
    _ -> panic as "expected Text"
  }
}

pub fn format_table_renders_box_drawing_lines_test() {
  widgets.format_table(["Name", "PnL"], [["AAPL", "+12"], ["TSLA", "-3"]], [
    widgets.AlignLeft,
    widgets.AlignRight,
  ])
  |> should.equal([
    "┌──────┬─────┐",
    "│ Name │ PnL │",
    "├──────┼─────┤",
    "│ AAPL │ +12 │",
    "│ TSLA │  -3 │",
    "└──────┴─────┘",
  ])
}

pub fn table_widget_renders_lines_as_text_rows_test() {
  case
    widgets.table([], ["Name", "Qty"], [["BTC", "2"]], [
      widgets.AlignLeft,
      widgets.AlignRight,
    ])
  {
    ui.Column(_, rows) ->
      rows
      |> should.equal([
        ui.Text([], "┌──────┬─────┐"),
        ui.Text([], "│ Name │ Qty │"),
        ui.Text([], "├──────┼─────┤"),
        ui.Text([], "│ BTC  │   2 │"),
        ui.Text([], "└──────┴─────┘"),
      ])
    _ -> panic as "expected Column"
  }
}

// ── Widget tests: SelectState ──

pub fn select_up_down_test() {
  let state = widgets.select_state(5)
  let _ = state.selected |> should.equal(0)
  let down = widgets.select_down(state)
  let _ = down.selected |> should.equal(1)
  let up = widgets.select_up(down)
  up.selected |> should.equal(0)
}

pub fn select_clamps_test() {
  let state = widgets.select_state(3)
  widgets.select_up(state).selected |> should.equal(0)
}

// ── Widget tests: TabState ──

pub fn tab_next_wraps_test() {
  let state = widgets.tab_state(3)
  let t1 = widgets.tab_next(state)
  let _ = t1.active |> should.equal(1)
  let t2 = widgets.tab_next(widgets.tab_next(t1))
  t2.active |> should.equal(0)
}

pub fn tab_prev_wraps_test() {
  let state = widgets.tab_state(3)
  let prev = widgets.tab_prev(state)
  prev.active |> should.equal(2)
}

// ── Interaction: FocusGroup tests ──

pub fn focus_next_wraps_test() {
  let group = interaction.focus_group(3)
  let g1 = interaction.focus_next(group)
  let _ = g1.focused |> should.equal(1)
  let g3 = interaction.focus_next(interaction.focus_next(g1))
  g3.focused |> should.equal(0)
}

pub fn focus_prev_wraps_test() {
  let group = interaction.focus_group(3)
  interaction.focus_prev(group).focused |> should.equal(2)
}

pub fn is_focused_test() {
  let group = interaction.focus_group(3)
  let _ = interaction.is_focused(group, 0) |> should.equal(True)
  interaction.is_focused(group, 1) |> should.equal(False)
}

pub fn click_region_find_hit_test() {
  let regions = [
    interaction.ClickRegion(1, 0, 0, 10, 5),
    interaction.ClickRegion(2, 15, 0, 10, 5),
  ]
  let _ = interaction.find_hit(regions, 5, 2) |> should.equal(Ok(1))
  let _ = interaction.find_hit(regions, 20, 2) |> should.equal(Ok(2))
  interaction.find_hit(regions, 12, 2) |> should.equal(Error(Nil))
}

// ── DrawPlan: new ops ──

pub fn draw_plan_hline_creates_op_test() {
  let op =
    draw_plan.hline(
      1,
      2,
      5,
      0x2500,
      draw_plan.Color(1.0, 1.0, 1.0, 1.0),
      draw_plan.Color(0.0, 0.0, 0.0, 0.0),
    )
  case op {
    draw_plan.HLine(1, 2, 5, 0x2500, _, _) -> Nil
    _ -> panic as "expected HLine"
  }
}

pub fn draw_plan_translate_test() {
  let plan = [
    draw_plan.text(
      0,
      0,
      "hi",
      draw_plan.Color(1.0, 1.0, 1.0, 1.0),
      draw_plan.Color(0.0, 0.0, 0.0, 0.0),
      0,
    ),
  ]
  let translated = draw_plan.translate(plan, 5, 3)
  case translated {
    [draw_plan.Text(5, 3, "hi", _, _, _)] -> Nil
    _ -> panic as "expected translated text"
  }
}
