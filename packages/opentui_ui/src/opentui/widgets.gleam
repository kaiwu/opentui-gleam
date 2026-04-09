import gleam/int
import gleam/list
import gleam/string
import opentui/ui.{
  type Color, type Element, type Style, Background, Column, Foreground, Height,
  Row, Text, Width,
}

// ── ScrollView ──

/// Pure scroll state: track offset and content/viewport dimensions.
pub type ScrollState {
  ScrollState(offset: Int, content_height: Int, viewport_height: Int)
}

pub fn scroll_state(viewport_height: Int) -> ScrollState {
  ScrollState(offset: 0, content_height: 0, viewport_height: viewport_height)
}

pub fn scroll_up(state: ScrollState, amount: Int) -> ScrollState {
  ScrollState(..state, offset: int.max(0, state.offset - amount))
}

pub fn scroll_down(state: ScrollState, amount: Int) -> ScrollState {
  let max_offset = int.max(0, state.content_height - state.viewport_height)
  ScrollState(..state, offset: int.min(max_offset, state.offset + amount))
}

pub fn scroll_to(state: ScrollState, offset: Int) -> ScrollState {
  let max_offset = int.max(0, state.content_height - state.viewport_height)
  ScrollState(..state, offset: clamp(offset, 0, max_offset))
}

pub fn set_content_height(state: ScrollState, height: Int) -> ScrollState {
  let max_offset = int.max(0, height - state.viewport_height)
  ScrollState(
    ..state,
    content_height: height,
    offset: int.min(state.offset, max_offset),
  )
}

/// Build a scroll view element. Renders visible children by offsetting the
/// Y position. Caller provides the full list of row elements; this function
/// slices to the visible window.
pub fn scroll_view(
  styles: List(Style),
  state: ScrollState,
  rows: List(Element),
) -> Element {
  let visible = slice_list(rows, state.offset, state.viewport_height)
  Column([Height(state.viewport_height), ..styles], visible)
}

// ── TextInput ──

/// Pure text input state.
pub type InputState {
  InputState(value: String, cursor: Int, focused: Bool)
}

pub fn input_state(initial: String) -> InputState {
  InputState(value: initial, cursor: string.length(initial), focused: True)
}

pub fn input_insert(state: InputState, ch: String) -> InputState {
  let before = string.slice(state.value, 0, state.cursor)
  let after =
    string.slice(
      state.value,
      state.cursor,
      string.length(state.value) - state.cursor,
    )
  InputState(
    ..state,
    value: before <> ch <> after,
    cursor: state.cursor + string.length(ch),
  )
}

pub fn input_delete_backward(state: InputState) -> InputState {
  case state.cursor > 0 {
    False -> state
    True -> {
      let before = string.slice(state.value, 0, state.cursor - 1)
      let after =
        string.slice(
          state.value,
          state.cursor,
          string.length(state.value) - state.cursor,
        )
      InputState(..state, value: before <> after, cursor: state.cursor - 1)
    }
  }
}

pub fn input_move_left(state: InputState) -> InputState {
  InputState(..state, cursor: int.max(0, state.cursor - 1))
}

pub fn input_move_right(state: InputState) -> InputState {
  InputState(
    ..state,
    cursor: int.min(string.length(state.value), state.cursor + 1),
  )
}

pub fn input_move_home(state: InputState) -> InputState {
  InputState(..state, cursor: 0)
}

pub fn input_move_end(state: InputState) -> InputState {
  InputState(..state, cursor: string.length(state.value))
}

pub fn input_blur(state: InputState) -> InputState {
  InputState(..state, focused: False)
}

pub fn input_focus(state: InputState) -> InputState {
  InputState(..state, focused: True)
}

pub fn input_display_value(state: InputState) -> String {
  let before = string.slice(state.value, 0, state.cursor)
  let after =
    string.slice(
      state.value,
      state.cursor,
      string.length(state.value) - state.cursor,
    )

  case state.focused {
    True -> before <> "█" <> after
    False -> before <> " " <> after
  }
}

/// Render a text input as a single-line Text element.
pub fn text_input(styles: List(Style), state: InputState) -> Element {
  Text(styles, input_display_value(state))
}

// ── Select ──

/// Pure selection state for a list of options.
pub type SelectState {
  SelectState(selected: Int, count: Int)
}

pub fn select_state(count: Int) -> SelectState {
  SelectState(selected: 0, count: count)
}

pub fn select_up(state: SelectState) -> SelectState {
  SelectState(..state, selected: int.max(0, state.selected - 1))
}

pub fn select_down(state: SelectState) -> SelectState {
  SelectState(..state, selected: int.min(state.count - 1, state.selected + 1))
}

pub fn select_set(state: SelectState, index: Int) -> SelectState {
  SelectState(..state, selected: clamp(index, 0, state.count - 1))
}

/// Render a select list. Each option is rendered as a Text element;
/// the selected option uses `selected_styles`, others use `normal_styles`.
pub fn select_list(
  styles: List(Style),
  state: SelectState,
  options: List(String),
  normal_styles: List(Style),
  selected_styles: List(Style),
) -> Element {
  let items =
    list.index_map(options, fn(label, i) {
      case i == state.selected {
        True -> Text(selected_styles, "> " <> label)
        False -> Text(normal_styles, "  " <> label)
      }
    })
  Column(styles, items)
}

// ── TabBar ──

/// Pure tab state.
pub type TabState {
  TabState(active: Int, count: Int)
}

pub fn tab_state(count: Int) -> TabState {
  TabState(active: 0, count: count)
}

pub fn tab_next(state: TabState) -> TabState {
  TabState(..state, active: { state.active + 1 } % state.count)
}

pub fn tab_prev(state: TabState) -> TabState {
  TabState(..state, active: { state.active - 1 + state.count } % state.count)
}

pub fn tab_set(state: TabState, index: Int) -> TabState {
  TabState(..state, active: clamp(index, 0, state.count - 1))
}

/// Render a tab bar as a Row of tab labels. Active tab uses
/// `active_styles`, others use `normal_styles`.
pub fn tab_bar(
  styles: List(Style),
  state: TabState,
  labels: List(String),
  normal_styles: List(Style),
  active_styles: List(Style),
) -> Element {
  let tabs =
    list.index_map(labels, fn(label, i) {
      case i == state.active {
        True -> Text(active_styles, " " <> label <> " ")
        False -> Text(normal_styles, " " <> label <> " ")
      }
    })
  Row(styles, tabs)
}

// ── CodeView ──

/// Render a code block with optional line numbers.
/// Takes a list of source lines, a start line number, and colors.
pub fn code_view(
  styles: List(Style),
  lines: List(String),
  start_line: Int,
  show_line_numbers: Bool,
  line_number_fg: Color,
  line_number_bg: Color,
  code_fg: Color,
  code_bg: Color,
) -> Element {
  let total = list.length(lines) + start_line - 1
  let gutter_w = case show_line_numbers {
    True -> int.max(2, string.length(int.to_string(total))) + 1
    False -> 0
  }

  let rows =
    list.index_map(lines, fn(line, i) {
      let line_num = start_line + i
      case show_line_numbers {
        True -> {
          let num_str =
            string.pad_start(int.to_string(line_num), gutter_w - 1, " ") <> " "
          Row([], [
            Text(
              [
                Width(gutter_w),
                Foreground(line_number_fg),
                Background(line_number_bg),
              ],
              num_str,
            ),
            Text([Foreground(code_fg), Background(code_bg)], line),
          ])
        }
        False -> Text([Foreground(code_fg), Background(code_bg)], line)
      }
    })

  Column(styles, rows)
}

// ── Helpers ──

fn clamp(value: Int, low: Int, high: Int) -> Int {
  int.max(low, int.min(high, value))
}

fn slice_list(items: List(a), start: Int, count: Int) -> List(a) {
  items
  |> drop_list(start)
  |> take_list(count)
}

fn drop_list(items: List(a), n: Int) -> List(a) {
  case n <= 0, items {
    True, _ -> items
    _, [] -> []
    _, [_, ..rest] -> drop_list(rest, n - 1)
  }
}

fn take_list(items: List(a), n: Int) -> List(a) {
  case n <= 0, items {
    True, _ -> []
    _, [] -> []
    _, [first, ..rest] -> [first, ..take_list(rest, n - 1)]
  }
}
