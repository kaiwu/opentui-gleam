import opentui/examples/common
import opentui/examples/phase2_model
import opentui/examples/phase2_state as state
import opentui/ffi
import opentui/input
import opentui/renderer
import opentui/ui

const list_hit_start = 10

pub fn main() -> Nil {
  let offset = state.create_int(0)
  let selected = state.create_int(0)

  common.run_event_ui_demo_with_setup(
    "Scrollbox Mouse Test",
    "Scrollbox Mouse Test",
    fn(r) { renderer.enable_mouse(r, True) },
    fn(r, event) { handle_event(r, offset, selected, event) },
    fn(r) { register_hits(r, offset) },
    fn() { view(offset, selected) },
  )
}

fn handle_event(
  renderer: ffi.Renderer,
  offset: state.IntCell,
  selected: state.IntCell,
  event: input.Event,
) -> Nil {
  case event {
    input.MouseEvent(input.MouseData(action:, button:, x:, y:, ..)) -> {
      let hit = input.hit_at(renderer, x, y)
      case action, button {
        input.MouseScroll, input.WheelUp ->
          state.set_int(
            offset,
            phase2_model.adjust_scroll(
              state.get_int(offset),
              phase2_model.ArrowUp,
              phase2_model.max_scroll_offset(12, 6),
            ),
          )
        input.MouseScroll, input.WheelDown ->
          state.set_int(
            offset,
            phase2_model.adjust_scroll(
              state.get_int(offset),
              phase2_model.ArrowDown,
              phase2_model.max_scroll_offset(12, 6),
            ),
          )
        input.MousePress, input.LeftButton ->
          case hit >= list_hit_start {
            True -> state.set_int(selected, hit - list_hit_start)
            False -> Nil
          }
        _, _ -> Nil
      }
    }
    _ -> Nil
  }
}

fn register_hits(renderer: ffi.Renderer, offset: state.IntCell) -> Nil {
  input.clear_hit_grid(renderer)
  register_row_hits(renderer, visible_items(state.get_int(offset)), 0)
}

fn register_row_hits(
  renderer: ffi.Renderer,
  items: List(String),
  index: Int,
) -> Nil {
  case items {
    [] -> Nil
    [_item, ..rest] -> {
      input.add_hit_region(
        renderer,
        5,
        7 + index * 2,
        40,
        1,
        list_hit_start + index,
      )
      register_row_hits(renderer, rest, index + 1)
    }
  }
}

fn view(offset: state.IntCell, selected: state.IntCell) -> List(ui.Element) {
  let current_offset = state.get_int(offset)
  let chosen = state.get_int(selected)

  [
    common.panel("Scrollbox", 2, 3, 46, 18, [
      ui.Column(
        [ui.Gap(1)],
        row_elements(visible_items(current_offset), 0, chosen),
      ),
    ]),
    common.panel("Mouse", 52, 3, 26, 18, [
      ui.Column([ui.Gap(1)], [
        common.line("Wheel scrolls visible rows"),
        common.line("Click selects a row"),
        common.line("Offset: " <> label_for(current_offset)),
        common.line("Selected: " <> label_for(chosen + 1)),
        ui.Spacer(1),
        common.paragraph(
          "The hit grid is rebuilt from the currently visible rows each frame, so clicks track the scrolled content rather than stale positions.",
        ),
      ]),
    ]),
  ]
}

fn row_elements(
  items: List(String),
  index: Int,
  selected: Int,
) -> List(ui.Element) {
  case items {
    [] -> []
    [item, ..rest] -> [
      common.line_with(
        case index == selected {
          True -> [
            ui.Foreground(common.color(common.accent_green)),
            ui.Attributes(1),
          ]
          False -> []
        },
        item,
      ),
      ui.Spacer(1),
      ..row_elements(rest, index + 1, selected)
    ]
  }
}

fn visible_items(offset: Int) -> List(String) {
  phase2_model.visible_lines(items(), offset, 6)
}

fn items() -> List(String) {
  [
    "row 01 mouse ready",
    "row 02 render tree",
    "row 03 visible hit ids",
    "row 04 offset changes",
    "row 05 selection sync",
    "row 06 hover pending",
    "row 07 wheel support",
    "row 08 overlay ready",
    "row 09 focus later",
    "row 10 docs update",
    "row 11 runtime tests",
    "row 12 examples green",
  ]
}

fn label_for(value: Int) -> String {
  case value {
    0 -> "0"
    1 -> "1"
    2 -> "2"
    3 -> "3"
    4 -> "4"
    5 -> "5"
    6 -> "6"
    _ -> "7"
  }
}
