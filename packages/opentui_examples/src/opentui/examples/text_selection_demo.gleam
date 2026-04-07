import gleam/int
import gleam/list
import gleam/string
import opentui/buffer
import opentui/examples/common
import opentui/examples/phase2_state as state
import opentui/examples/phase3_model as model
import opentui/examples/text_selection_semantics as semantics
import opentui/ffi
import opentui/input
import opentui/renderer

type VisualLeaf {
  VisualLeaf(
    x: Int,
    y: Int,
    fg: #(Float, Float, Float, Float),
    leaf: semantics.TextLeaf,
  )
}

type LocatedLeaf {
  LocatedLeaf(visual: VisualLeaf, start: Int)
}

pub fn main() -> Nil {
  let anchor = state.create_int(0)
  let focus = state.create_int(0)
  let dragging = state.create_bool(False)
  let has_selection = state.create_bool(False)

  common.run_event_demo_with_setup(
    "Text Selection Demo",
    "Text Selection Demo",
    fn(r) { renderer.enable_mouse(r, True) },
    fn(_renderer, event) {
      handle_event(anchor, focus, dragging, has_selection, event)
    },
    fn(_renderer, buf) { draw(buf, anchor, focus, dragging, has_selection) },
  )
}

fn handle_event(
  anchor: state.IntCell,
  focus: state.IntCell,
  dragging: state.BoolCell,
  has_selection: state.BoolCell,
  event: input.Event,
) -> Nil {
  let located = located_leaves()

  case event {
    input.KeyEvent(_, key) ->
      case key {
        input.Character("c") | input.Character("C") -> {
          state.set_int(anchor, 0)
          state.set_int(focus, 0)
          state.set_bool(dragging, False)
          state.set_bool(has_selection, False)
        }
        _ -> Nil
      }
    input.MouseEvent(input.MouseData(action:, button:, x:, y:, ..)) ->
      case action, button {
        input.MousePress, input.LeftButton ->
          case position_to_index(located, x, y) {
            Ok(index) -> {
              state.set_int(anchor, index)
              state.set_int(focus, index)
              state.set_bool(dragging, True)
              state.set_bool(has_selection, True)
            }
            Error(_) -> {
              state.set_bool(dragging, False)
              state.set_bool(has_selection, False)
            }
          }
        input.MouseDrag, _ ->
          case state.get_bool(dragging), position_to_index(located, x, y) {
            True, Ok(index) -> state.set_int(focus, index)
            _, _ -> Nil
          }
        input.MouseRelease, _ -> state.set_bool(dragging, False)
        _, _ -> Nil
      }
    _ -> Nil
  }
}

fn draw(
  buf: ffi.Buffer,
  anchor: state.IntCell,
  focus: state.IntCell,
  dragging: state.BoolCell,
  has_selection: state.BoolCell,
) -> Nil {
  let visuals = visual_leaves()
  let located = located_leaves()
  let selection = model.Selection(state.get_int(anchor), state.get_int(focus))
  let report =
    semantics.build_report(
      list.map(visuals, fn(visual) { visual.leaf }),
      state.get_bool(has_selection),
      selection,
    )

  common.draw_panel(buf, 2, 2, 38, 10, "Document Section 1")
  common.draw_panel(buf, 42, 2, 36, 10, "Code Example")
  common.draw_panel(buf, 6, 8, 28, 3, "Nested Box")
  common.draw_panel(buf, 18, 12, 44, 5, "README")
  common.draw_panel(buf, 2, 17, 76, 6, "Selection Status")

  draw_visuals(buf, located, selection)

  buffer.draw_text(
    buf,
    "Click and drag to select across elements. Press c to clear selection.",
    4,
    19,
    common.fg_color,
    common.panel_bg,
    0,
  )
  buffer.draw_text(
    buf,
    status_title(report),
    4,
    20,
    common.accent_blue,
    common.panel_bg,
    0,
  )
  buffer.draw_text(
    buf,
    status_excerpt(report),
    4,
    21,
    common.muted_fg,
    common.panel_bg,
    0,
  )
  buffer.draw_text(
    buf,
    debug_line(report, state.get_bool(dragging)),
    4,
    22,
    common.fg_color,
    common.panel_bg,
    0,
  )
}

fn draw_visuals(
  buf: ffi.Buffer,
  located: List(LocatedLeaf),
  selection: model.Selection,
) -> Nil {
  case located {
    [] -> Nil
    [LocatedLeaf(visual:, start:), ..rest] -> {
      draw_visual(buf, visual, start, selection)
      draw_visuals(buf, rest, selection)
    }
  }
}

fn draw_visual(
  buf: ffi.Buffer,
  visual: VisualLeaf,
  start: Int,
  selection: model.Selection,
) -> Nil {
  draw_chars(
    buf,
    string.to_graphemes(visual.leaf.text),
    visual.x,
    visual.y,
    start,
    visual.fg,
    selection,
  )
}

fn draw_chars(
  buf: ffi.Buffer,
  chars: List(String),
  x: Int,
  y: Int,
  index: Int,
  fg: #(Float, Float, Float, Float),
  selection: model.Selection,
) -> Nil {
  case chars {
    [] -> Nil
    [char, ..rest] -> {
      let selected = model.selection_contains(selection, index)
      buffer.draw_text(
        buf,
        char,
        x,
        y,
        case selected {
          True -> common.bg_color
          False -> fg
        },
        case selected {
          True -> common.accent_yellow
          False -> common.panel_bg
        },
        case selected {
          True -> 1
          False -> 0
        },
      )
      draw_chars(buf, rest, x + 1, y, index + 1, fg, selection)
    }
  }
}

fn status_title(report: semantics.SelectionReport) -> String {
  case report.state {
    semantics.NoSelection ->
      "No selection - try selecting across different nested elements"
    semantics.EmptySelection ->
      "Empty selection in " <> report.primary_container_label
    semantics.ActiveSelection ->
      case report.line_count > 1 {
        True ->
          "Selected "
          <> int.to_string(report.line_count)
          <> " lines ("
          <> int.to_string(report.selected_chars)
          <> " chars):"
        False ->
          "Selected " <> int.to_string(report.selected_chars) <> " chars:"
      }
  }
}

fn status_excerpt(report: semantics.SelectionReport) -> String {
  case report.state {
    semantics.NoSelection -> "Selected text: (none)"
    semantics.EmptySelection -> "Selected text: (empty selection)"
    semantics.ActiveSelection ->
      case report.excerpt_middle {
        "" -> "Selected text: " <> report.excerpt_start
        _ ->
          "Selected text: "
          <> report.excerpt_start
          <> " "
          <> report.excerpt_middle
          <> " "
          <> report.excerpt_end
      }
  }
}

fn debug_line(report: semantics.SelectionReport, dragging: Bool) -> String {
  let mode = case dragging {
    True -> "dragging"
    False -> "idle"
  }

  "Selected renderables: "
  <> int.to_string(report.selected_renderables)
  <> "/"
  <> int.to_string(report.total_renderables)
  <> " | Containers: "
  <> int.to_string(report.selected_containers)
  <> "/"
  <> int.to_string(report.total_containers)
  <> " | Container: "
  <> report.primary_container_label
  <> " | mode="
  <> mode
}

fn position_to_index(
  located: List(LocatedLeaf),
  x: Int,
  y: Int,
) -> Result(Int, Nil) {
  case located {
    [] -> Error(Nil)
    [LocatedLeaf(visual:, start:), ..rest] -> {
      let width = string.length(visual.leaf.text)
      case y == visual.y && x >= visual.x && x < visual.x + width {
        True -> Ok(start + x - visual.x)
        False -> position_to_index(rest, x, y)
      }
    }
  }
}

fn located_leaves() -> List(LocatedLeaf) {
  build_located_leaves(visual_leaves(), 0, [])
}

fn build_located_leaves(
  pending: List(VisualLeaf),
  start: Int,
  acc: List(LocatedLeaf),
) -> List(LocatedLeaf) {
  case pending {
    [] -> list.reverse(acc)
    [visual, ..rest] -> {
      let next_start = start + string.length(visual.leaf.text) + 1
      build_located_leaves(rest, next_start, [
        LocatedLeaf(visual: visual, start: start),
        ..acc
      ])
    }
  }
}

fn visual_leaves() -> List(VisualLeaf) {
  [
    VisualLeaf(
      4,
      4,
      common.fg_color,
      semantics.TextLeaf(
        "left-panel",
        "Document Section 1",
        "text1",
        "Paragraph 1",
        "This is a paragraph in the first box.",
      ),
    ),
    VisualLeaf(
      4,
      5,
      common.fg_color,
      semantics.TextLeaf(
        "left-panel",
        "Document Section 1",
        "text2",
        "Paragraph 2",
        "Select this text with the mouse.",
      ),
    ),
    VisualLeaf(
      4,
      6,
      common.fg_color,
      semantics.TextLeaf(
        "left-panel",
        "Document Section 1",
        "text3",
        "Paragraph 3",
        "Drag into code or README to extend.",
      ),
    ),
    VisualLeaf(
      4,
      7,
      common.muted_fg,
      semantics.TextLeaf(
        "left-panel",
        "Document Section 1",
        "text4",
        "Paragraph 4",
        "Selection crosses render boundaries.",
      ),
    ),
    VisualLeaf(
      8,
      9,
      common.accent_yellow,
      semantics.TextLeaf(
        "nested-box",
        "Nested Box",
        "nested1",
        "Nested label",
        "Important:",
      ),
    ),
    VisualLeaf(
      19,
      9,
      common.accent_blue,
      semantics.TextLeaf(
        "nested-box",
        "Nested Box",
        "nested2",
        "Nested body",
        "nested content",
      ),
    ),
    VisualLeaf(
      34,
      9,
      common.accent_green,
      semantics.TextLeaf(
        "nested-box",
        "Nested Box",
        "nested3",
        "Nested badge",
        "✓",
      ),
    ),
    VisualLeaf(
      44,
      4,
      common.accent_pink,
      semantics.TextLeaf(
        "code-panel",
        "Code Example",
        "code1",
        "Code line 1",
        "function handleSelection() {",
      ),
    ),
    VisualLeaf(
      44,
      5,
      common.accent_blue,
      semantics.TextLeaf(
        "code-panel",
        "Code Example",
        "code2",
        "Code line 2",
        "  const picked = getSelectedText()",
      ),
    ),
    VisualLeaf(
      44,
      6,
      common.accent_green,
      semantics.TextLeaf(
        "code-panel",
        "Code Example",
        "code3",
        "Code line 3",
        "  console.log(picked)",
      ),
    ),
    VisualLeaf(
      44,
      7,
      common.accent_orange,
      semantics.TextLeaf(
        "code-panel",
        "Code Example",
        "code4",
        "Code line 4",
        "}",
      ),
    ),
    VisualLeaf(
      20,
      14,
      common.accent_blue,
      semantics.TextLeaf(
        "readme-panel",
        "README",
        "readme1",
        "README title",
        "Selection Demo",
      ),
    ),
    VisualLeaf(
      20,
      15,
      common.fg_color,
      semantics.TextLeaf(
        "readme-panel",
        "README",
        "readme2",
        "README line 1",
        "Cross-panel drag selection",
      ),
    ),
    VisualLeaf(
      20,
      16,
      common.muted_fg,
      semantics.TextLeaf(
        "readme-panel",
        "README",
        "readme3",
        "README line 2",
        "Press c to clear the current range",
      ),
    ),
  ]
}
