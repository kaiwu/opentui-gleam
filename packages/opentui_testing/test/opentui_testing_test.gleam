import gleam/list
import gleeunit
import gleeunit/should
import opentui/input
import opentui/testing
import opentui/ui
import opentui/widgets

pub fn main() {
  gleeunit.main()
}

// ── Synthetic input tests ──

pub fn arrow_up_produces_key_event_test() {
  case testing.arrow_up() {
    input.KeyEvent(_, input.ArrowUp) -> Nil
    _ -> panic as "expected ArrowUp"
  }
}

pub fn arrow_down_produces_key_event_test() {
  case testing.arrow_down() {
    input.KeyEvent(_, input.ArrowDown) -> Nil
    _ -> panic as "expected ArrowDown"
  }
}

pub fn char_produces_character_event_test() {
  case testing.char("a") {
    input.KeyEvent("a", input.Character("a")) -> Nil
    _ -> panic as "expected Character(a)"
  }
}

pub fn tab_produces_tab_event_test() {
  case testing.tab() {
    input.KeyEvent(_, input.Tab) -> Nil
    _ -> panic as "expected Tab"
  }
}

pub fn mouse_press_produces_mouse_event_test() {
  case testing.mouse_press(5, 10) {
    input.MouseEvent(data) -> {
      let _ = data.x |> should.equal(5)
      let _ = data.y |> should.equal(10)
      data.action |> should.equal(input.MousePress)
    }
    _ -> panic as "expected MouseEvent"
  }
}

pub fn mouse_scroll_up_test() {
  case testing.mouse_scroll_up(0, 0) {
    input.MouseEvent(data) ->
      data.button |> should.equal(input.WheelUp)
    _ -> panic as "expected MouseEvent"
  }
}

// ── State machine testing ──

pub fn apply_events_select_navigation_test() {
  let initial = widgets.select_state(5)
  let events = [testing.arrow_down(), testing.arrow_down(), testing.arrow_up()]

  let final_state =
    testing.apply_events(initial, events, fn(s, event) {
      case event {
        input.KeyEvent(_, input.ArrowDown) -> widgets.select_down(s)
        input.KeyEvent(_, input.ArrowUp) -> widgets.select_up(s)
        _ -> s
      }
    })

  final_state.selected |> should.equal(1)
}

pub fn apply_keys_input_test() {
  let initial = widgets.input_state("")
  let final_state =
    testing.apply_keys(initial, ["h", "i"], fn(s, event) {
      case event {
        input.KeyEvent(_, input.Character(c)) -> widgets.input_insert(s, c)
        _ -> s
      }
    })

  final_state.value |> should.equal("hi")
}

// ── Element tree inspection ──

pub fn count_elements_test() {
  let tree = [
    ui.Column([], [ui.Text([], "a"), ui.Text([], "b")]),
    ui.Text([], "c"),
  ]
  testing.count_elements(tree) |> should.equal(4)
}

pub fn element_texts_test() {
  let tree = [
    ui.Column([], [ui.Text([], "hello"), ui.Text([], "world")]),
  ]
  testing.element_texts(tree) |> should.equal(["hello", "world"])
}

pub fn tree_contains_text_test() {
  let tree = [ui.Text([], "hello world")]
  let _ = testing.tree_contains_text(tree, "world") |> should.equal(True)
  testing.tree_contains_text(tree, "xyz") |> should.equal(False)
}

// ── Layout plan inspection ──

pub fn find_nodes_by_kind_test() {
  let nodes = testing.plan_snapshot(
    [ui.Column([], [ui.Text([ui.Width(10)], "a"), ui.Spacer(1)])],
    80, 24,
  )
  let texts = testing.find_nodes(nodes, "Text")
  list.length(texts) |> should.equal(1)
}

pub fn layout_bounds_test() {
  let nodes = testing.plan_snapshot(
    [
      ui.Box([ui.X(5), ui.Y(3), ui.Width(20), ui.Height(10)], [
        ui.Text([], "content"),
      ]),
    ],
    80, 24,
  )
  let #(min_x, min_y, max_x, max_y) = testing.layout_bounds(nodes)
  let _ = min_x |> should.equal(5)
  let _ = min_y |> should.equal(3)
  let _ = max_x |> should.equal(25)
  max_y |> should.equal(13)
}

// ── Snapshot ──

pub fn snapshot_contains_element_info_test() {
  let s = testing.snapshot([ui.Text([], "hello")])
  { s != "" } |> should.equal(True)
}

// ── Widget trace ──

pub fn trace_widget_captures_states_test() {
  let events = [testing.arrow_down(), testing.arrow_down()]

  let trace =
    testing.trace_widget(
      widgets.select_state(5),
      events,
      fn(s, event) {
        case event {
          input.KeyEvent(_, input.ArrowDown) -> widgets.select_down(s)
          _ -> s
        }
      },
      fn(s) {
        [ui.Text([], "selected: " <> case s.selected {
          0 -> "0"
          1 -> "1"
          _ -> "other"
        })]
      },
    )

  // initial + 2 events = 3 frames
  list.length(trace) |> should.equal(3)

  // Check first and last state
  case trace {
    [#(first, _), _, #(last, _)] -> {
      let _ = first.selected |> should.equal(0)
      last.selected |> should.equal(2)
    }
    _ -> panic as "expected 3 trace entries"
  }
}
