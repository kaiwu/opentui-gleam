import gleam/list
import gleam/string
import opentui/examples/phase3_model as selection_model

pub type TextLeaf {
  TextLeaf(
    container_id: String,
    container_label: String,
    renderable_id: String,
    renderable_label: String,
    text: String,
  )
}

pub type SelectionState {
  NoSelection
  EmptySelection
  ActiveSelection
}

pub type SelectionReport {
  SelectionReport(
    state: SelectionState,
    selected_chars: Int,
    line_count: Int,
    selected_renderables: Int,
    total_renderables: Int,
    selected_containers: Int,
    total_containers: Int,
    primary_container_label: String,
    selected_text: String,
    excerpt_start: String,
    excerpt_middle: String,
    excerpt_end: String,
  )
}

type IndexedLeaf {
  IndexedLeaf(leaf: TextLeaf, start: Int)
}

pub fn build_report(
  leaves: List(TextLeaf),
  has_selection: Bool,
  selection: selection_model.Selection,
) -> SelectionReport {
  let indexed = index_leaves(leaves, 0, [])
  let state = selection_state(has_selection, selection)
  let selected_text = selection_text(indexed, state, selection)
  let active = selected_leaves(indexed, state, selection)
  let #(excerpt_start, excerpt_middle, excerpt_end) =
    excerpt_parts(selected_text)

  SelectionReport(
    state: state,
    selected_chars: string.length(selected_text),
    line_count: line_count(selected_text),
    selected_renderables: distinct_renderable_count(active),
    total_renderables: distinct_renderable_count(indexed),
    selected_containers: distinct_container_count(active),
    total_containers: distinct_container_count(indexed),
    primary_container_label: primary_container_label(
      indexed,
      active,
      state,
      selection,
    ),
    selected_text: selected_text,
    excerpt_start: excerpt_start,
    excerpt_middle: excerpt_middle,
    excerpt_end: excerpt_end,
  )
}

fn selection_state(
  has_selection: Bool,
  selection: selection_model.Selection,
) -> SelectionState {
  case has_selection {
    False -> NoSelection
    True ->
      case selection.anchor == selection.focus {
        True -> EmptySelection
        False -> ActiveSelection
      }
  }
}

fn selection_text(
  indexed: List(IndexedLeaf),
  state: SelectionState,
  selection: selection_model.Selection,
) -> String {
  case state {
    ActiveSelection -> {
      let #(lo, hi) = selection_model.selection_range(selection)
      document_text(indexed)
      |> string.to_graphemes
      |> list.drop(lo)
      |> list.take(hi - lo)
      |> string.join("")
    }
    _ -> ""
  }
}

fn selected_leaves(
  indexed: List(IndexedLeaf),
  state: SelectionState,
  selection: selection_model.Selection,
) -> List(IndexedLeaf) {
  case state {
    ActiveSelection -> {
      let #(lo, hi) = selection_model.selection_range(selection)
      collect_selected_leaves(indexed, lo, hi, [])
    }
    _ -> []
  }
}

fn collect_selected_leaves(
  indexed: List(IndexedLeaf),
  lo: Int,
  hi: Int,
  acc: List(IndexedLeaf),
) -> List(IndexedLeaf) {
  case indexed {
    [] -> list.reverse(acc)
    [IndexedLeaf(leaf:, start:), ..rest] -> {
      let end = start + string.length(leaf.text)
      let intersects = lo < end && hi > start
      case intersects {
        True ->
          collect_selected_leaves(rest, lo, hi, [
            IndexedLeaf(leaf: leaf, start: start),
            ..acc
          ])
        False -> collect_selected_leaves(rest, lo, hi, acc)
      }
    }
  }
}

fn primary_container_label(
  indexed: List(IndexedLeaf),
  active: List(IndexedLeaf),
  state: SelectionState,
  selection: selection_model.Selection,
) -> String {
  case state {
    NoSelection -> "none"
    EmptySelection ->
      case leaf_at_position(indexed, selection.focus) {
        Ok(leaf) -> leaf.container_label
        Error(_) -> "none"
      }
    ActiveSelection ->
      case distinct_container_labels(active, []) {
        [label] -> label
        [] -> "none"
        _ -> "multiple containers"
      }
  }
}

fn leaf_at_position(
  indexed: List(IndexedLeaf),
  position: Int,
) -> Result(TextLeaf, Nil) {
  case indexed {
    [] -> Error(Nil)
    [IndexedLeaf(leaf:, start:), ..rest] -> {
      let end = start + string.length(leaf.text)
      case position >= start && position < end {
        True -> Ok(leaf)
        False -> leaf_at_position(rest, position)
      }
    }
  }
}

fn line_count(text: String) -> Int {
  case text {
    "" -> 0
    _ -> list.length(string.split(text, "\n"))
  }
}

fn excerpt_parts(text: String) -> #(String, String, String) {
  case text {
    "" -> #("", "", "")
    _ -> {
      let lines = string.split(text, "\n")
      case list.length(lines) > 1 {
        True -> {
          let first = first_string(lines)
          let last = last_string(lines)
          #(truncate(first, 24), "...", truncate(last, 24))
        }
        False ->
          case string.length(text) > 60 {
            True -> {
              let len = string.length(text)
              #(
                string.slice(text, 0, 28),
                "...",
                string.slice(text, len - 28, 28),
              )
            }
            False -> #("\"" <> text <> "\"", "", "")
          }
      }
    }
  }
}

fn truncate(text: String, limit: Int) -> String {
  case string.length(text) > limit {
    True -> string.slice(text, 0, limit) <> "..."
    False -> text
  }
}

fn first_string(items: List(String)) -> String {
  case items {
    [item, ..] -> item
    [] -> ""
  }
}

fn last_string(items: List(String)) -> String {
  case items {
    [] -> ""
    [item] -> item
    [_, ..rest] -> last_string(rest)
  }
}

fn distinct_renderable_count(indexed: List(IndexedLeaf)) -> Int {
  indexed
  |> distinct_renderable_ids([])
  |> list.length
}

fn distinct_renderable_ids(
  indexed: List(IndexedLeaf),
  acc: List(String),
) -> List(String) {
  case indexed {
    [] -> acc
    [IndexedLeaf(leaf:, ..), ..rest] -> {
      let next = case contains_string(acc, leaf.renderable_id) {
        True -> acc
        False -> [leaf.renderable_id, ..acc]
      }
      distinct_renderable_ids(rest, next)
    }
  }
}

fn distinct_container_count(indexed: List(IndexedLeaf)) -> Int {
  indexed
  |> distinct_container_ids([])
  |> list.length
}

fn distinct_container_ids(
  indexed: List(IndexedLeaf),
  acc: List(String),
) -> List(String) {
  case indexed {
    [] -> acc
    [IndexedLeaf(leaf:, ..), ..rest] -> {
      let next = case contains_string(acc, leaf.container_id) {
        True -> acc
        False -> [leaf.container_id, ..acc]
      }
      distinct_container_ids(rest, next)
    }
  }
}

fn distinct_container_labels(
  indexed: List(IndexedLeaf),
  acc: List(String),
) -> List(String) {
  case indexed {
    [] -> list.reverse(acc)
    [IndexedLeaf(leaf:, ..), ..rest] -> {
      let next = case contains_string(acc, leaf.container_label) {
        True -> acc
        False -> [leaf.container_label, ..acc]
      }
      distinct_container_labels(rest, next)
    }
  }
}

fn contains_string(items: List(String), target: String) -> Bool {
  case items {
    [] -> False
    [item, ..rest] ->
      case item == target {
        True -> True
        False -> contains_string(rest, target)
      }
  }
}

fn document_text(indexed: List(IndexedLeaf)) -> String {
  join_leaf_text(indexed, "")
}

fn join_leaf_text(indexed: List(IndexedLeaf), acc: String) -> String {
  case indexed {
    [] -> acc
    [IndexedLeaf(leaf:, ..), ..rest] ->
      case acc {
        "" -> join_leaf_text(rest, leaf.text)
        _ -> join_leaf_text(rest, acc <> "\n" <> leaf.text)
      }
  }
}

fn index_leaves(
  leaves: List(TextLeaf),
  start: Int,
  acc: List(IndexedLeaf),
) -> List(IndexedLeaf) {
  case leaves {
    [] -> list.reverse(acc)
    [leaf, ..rest] -> {
      let next_start = start + string.length(leaf.text) + 1
      index_leaves(rest, next_start, [
        IndexedLeaf(leaf: leaf, start: start),
        ..acc
      ])
    }
  }
}
