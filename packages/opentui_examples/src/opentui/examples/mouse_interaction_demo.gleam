import opentui/examples/common
import opentui/examples/phase2_state as state
import opentui/ffi
import opentui/input
import opentui/renderer
import opentui/ui

const left_hit = 1

const right_hit = 2

pub fn main() -> Nil {
  let active = state.create_int(left_hit)
  let wheel_count = state.create_int(0)
  let status = state.create_int(0)

  common.run_event_ui_demo_with_setup(
    "Mouse Interaction Demo",
    "Mouse Interaction Demo",
    fn(r) { renderer.enable_mouse(r, True) },
    fn(r, event) { handle_event(r, active, wheel_count, status, event) },
    register_hits,
    fn() { view(active, wheel_count, status) },
  )
}

fn handle_event(
  renderer: ffi.Renderer,
  active: state.IntCell,
  wheel_count: state.IntCell,
  status: state.IntCell,
  event: input.Event,
) -> Nil {
  case event {
    input.MouseEvent(input.MouseData(action:, button:, x:, y:, ..)) -> {
      let hit = input.hit_at(renderer, x, y)
      case action, button {
        input.MousePress, input.LeftButton -> {
          case hit == left_hit || hit == right_hit {
            True -> state.set_int(active, hit)
            False -> Nil
          }
          state.set_int(status, hit)
        }
        input.MouseScroll, input.WheelUp ->
          state.set_int(wheel_count, state.get_int(wheel_count) + 1)
        input.MouseScroll, input.WheelDown ->
          state.set_int(wheel_count, state.get_int(wheel_count) - 1)
        _, _ -> Nil
      }
    }
    _ -> Nil
  }
}

fn register_hits(renderer: ffi.Renderer) -> Nil {
  input.clear_hit_grid(renderer)
  input.add_hit_region(renderer, 6, 7, 26, 8, left_hit)
  input.add_hit_region(renderer, 48, 7, 26, 8, right_hit)
}

fn view(
  active: state.IntCell,
  wheel_count: state.IntCell,
  status: state.IntCell,
) -> List(ui.Element) {
  let selected = state.get_int(active)

  [
    card("Primary", 6, 7, selected == left_hit),
    card("Secondary", 48, 7, selected == right_hit),
    common.panel("Mouse state", 2, 17, 76, 4, [
      ui.Column([ui.Gap(1)], [
        common.line("Wheel delta: " <> label_for(state.get_int(wheel_count))),
        common.line("Last hit id: " <> label_for(state.get_int(status))),
      ]),
    ]),
    common.panel("Notes", 2, 3, 76, 3, [
      ui.Column([ui.Gap(1)], [
        common.line(
          "Click a card to activate it. Mouse wheel updates the counter through the new runtime input/event path.",
        ),
      ]),
    ]),
  ]
}

fn card(title: String, x: Int, y: Int, active: Bool) -> ui.Element {
  common.panel_with_background(
    title,
    x,
    y,
    26,
    8,
    case active {
      True -> common.accent_blue
      False -> common.panel_bg
    },
    [
      ui.Column([ui.Gap(1)], [
        common.line_with(
          [
            ui.Foreground(common.color(common.bg_color)),
            ui.Background(
              common.color(case active {
                True -> common.accent_blue
                False -> common.panel_bg
              }),
            ),
            ui.Attributes(1),
          ],
          case active {
            True -> "active"
            False -> "idle"
          },
        ),
        common.line("hit grid backed"),
      ]),
    ],
  )
}

fn label_for(value: Int) -> String {
  case value {
    -3 -> "-3"
    -2 -> "-2"
    -1 -> "-1"
    0 -> "0"
    1 -> "1"
    2 -> "2"
    3 -> "3"
    _ -> "4"
  }
}
