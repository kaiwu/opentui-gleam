import gleam/list
import gleam/string
import opentui/input
import opentui/ui

// ── Synthetic Key Events ──

pub fn key_event(raw: String) -> input.Event {
  input.KeyEvent(raw, input.parse_key(raw))
}

pub fn arrow_up() -> input.Event {
  key_event("\u{1b}[A")
}

pub fn arrow_down() -> input.Event {
  key_event("\u{1b}[B")
}

pub fn arrow_left() -> input.Event {
  key_event("\u{1b}[D")
}

pub fn arrow_right() -> input.Event {
  key_event("\u{1b}[C")
}

pub fn enter() -> input.Event {
  key_event("\r")
}

pub fn tab() -> input.Event {
  key_event("\t")
}

pub fn shift_tab() -> input.Event {
  key_event("\u{1b}[Z")
}

pub fn backspace() -> input.Event {
  key_event("\u{7f}")
}

pub fn escape() -> input.Event {
  key_event("\u{1b}")
}

pub fn home() -> input.Event {
  key_event("\u{1b}[H")
}

pub fn end() -> input.Event {
  key_event("\u{1b}[F")
}

pub fn char(c: String) -> input.Event {
  key_event(c)
}

pub fn space() -> input.Event {
  key_event(" ")
}

// ── Synthetic Mouse Events ──

pub fn mouse_press(x: Int, y: Int) -> input.Event {
  input.MouseEvent(input.MouseData(
    action: input.MousePress,
    button: input.LeftButton,
    x: x,
    y: y,
    shift: False,
    alt: False,
    ctrl: False,
  ))
}

pub fn mouse_release(x: Int, y: Int) -> input.Event {
  input.MouseEvent(input.MouseData(
    action: input.MouseRelease,
    button: input.LeftButton,
    x: x,
    y: y,
    shift: False,
    alt: False,
    ctrl: False,
  ))
}

pub fn mouse_scroll_up(x: Int, y: Int) -> input.Event {
  input.MouseEvent(input.MouseData(
    action: input.MouseScroll,
    button: input.WheelUp,
    x: x,
    y: y,
    shift: False,
    alt: False,
    ctrl: False,
  ))
}

pub fn mouse_scroll_down(x: Int, y: Int) -> input.Event {
  input.MouseEvent(input.MouseData(
    action: input.MouseScroll,
    button: input.WheelDown,
    x: x,
    y: y,
    shift: False,
    alt: False,
    ctrl: False,
  ))
}

// ── State Machine Testing ──

/// Apply a sequence of events to a state using an update function.
/// Returns the final state after all events are processed.
pub fn apply_events(
  state: s,
  events: List(input.Event),
  update: fn(s, input.Event) -> s,
) -> s {
  case events {
    [] -> state
    [event, ..rest] -> apply_events(update(state, event), rest, update)
  }
}

/// Apply a sequence of raw key strings to a state.
pub fn apply_keys(
  state: s,
  keys: List(String),
  update: fn(s, input.Event) -> s,
) -> s {
  apply_events(state, list.map(keys, key_event), update)
}

// ── Element Tree Inspection ──

/// Count all elements in a tree (including nested children).
pub fn count_elements(elements: List(ui.Element)) -> Int {
  ui.fold(elements, 0, fn(acc, _el) { acc + 1 })
}

/// Extract all text content from Text elements in the tree.
pub fn element_texts(elements: List(ui.Element)) -> List(String) {
  ui.fold(elements, [], fn(acc, el) {
    case el {
      ui.Text(_, content) -> list.append(acc, [content])
      _ -> acc
    }
  })
}

/// Check if any Text element in the tree contains the given substring.
pub fn tree_contains_text(elements: List(ui.Element), needle: String) -> Bool {
  let texts = element_texts(elements)
  list.any(texts, fn(t) { string.contains(t, needle) })
}

// ── Layout Plan Inspection ──

/// Find all layout nodes matching a kind (e.g. "Box", "Text", "Column").
pub fn find_nodes(
  nodes: List(ui.LayoutNode),
  kind: String,
) -> List(ui.LayoutNode) {
  list.flat_map(nodes, fn(node) { find_in_node(node, kind) })
}

fn find_in_node(node: ui.LayoutNode, kind: String) -> List(ui.LayoutNode) {
  let self = case node.kind == kind {
    True -> [node]
    False -> []
  }
  list.append(self, list.flat_map(node.children, fn(c) {
    find_in_node(c, kind)
  }))
}

/// Get the bounding box of all nodes as (min_x, min_y, max_x, max_y).
pub fn layout_bounds(
  nodes: List(ui.LayoutNode),
) -> #(Int, Int, Int, Int) {
  let all = list.flat_map(nodes, fn(n) { flatten_node(n) })
  case all {
    [] -> #(0, 0, 0, 0)
    [first, ..rest] ->
      list.fold(rest, #(first.x, first.y, first.x + first.width, first.y + first.height), fn(acc, n) {
        let #(min_x, min_y, max_x, max_y) = acc
        #(
          int_min(min_x, n.x),
          int_min(min_y, n.y),
          int_max(max_x, n.x + n.width),
          int_max(max_y, n.y + n.height),
        )
      })
  }
}

fn flatten_node(node: ui.LayoutNode) -> List(ui.LayoutNode) {
  [node, ..list.flat_map(node.children, flatten_node)]
}

// ── Frame Snapshot ──

/// Render an element tree to a string snapshot via ui.to_string.
pub fn snapshot(elements: List(ui.Element)) -> String {
  ui.to_string(elements)
}

/// Plan a layout and return the node tree for assertion.
pub fn plan_snapshot(
  elements: List(ui.Element),
  width: Int,
  height: Int,
) -> List(ui.LayoutNode) {
  ui.plan(elements, width, height)
}

// ── Widget Verification Harness ──

/// Run a widget through a sequence of events, capturing the view after each event.
/// Returns a list of (state, element_tree) pairs — one per event, plus the initial state.
pub fn trace_widget(
  initial: s,
  events: List(input.Event),
  update: fn(s, input.Event) -> s,
  view: fn(s) -> List(ui.Element),
) -> List(#(s, List(ui.Element))) {
  let initial_frame = #(initial, view(initial))
  trace_loop(initial, events, update, view, [initial_frame])
}

fn trace_loop(
  state: s,
  events: List(input.Event),
  update: fn(s, input.Event) -> s,
  view: fn(s) -> List(ui.Element),
  acc: List(#(s, List(ui.Element))),
) -> List(#(s, List(ui.Element))) {
  case events {
    [] -> list.reverse(acc)
    [event, ..rest] -> {
      let new_state = update(state, event)
      let frame = #(new_state, view(new_state))
      trace_loop(new_state, rest, update, view, [frame, ..acc])
    }
  }
}

// ── Helpers ──

fn int_min(a: Int, b: Int) -> Int {
  case a < b {
    True -> a
    False -> b
  }
}

fn int_max(a: Int, b: Int) -> Int {
  case a > b {
    True -> a
    False -> b
  }
}
