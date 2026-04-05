import opentui/examples/common
import opentui/examples/phase2_state as state
import opentui/ffi
import opentui/input
import opentui/renderer
import opentui/ui

const overlay_hit = 100

const dialog_hit = 200

const button_hit = 201

pub fn main() -> Nil {
  let overlay_visible = state.create_bool(True)
  let status = state.create_int(overlay_hit)

  common.run_event_ui_demo_with_setup(
    "Scrollbox Overlay Hit Test",
    "Scrollbox Overlay Hit Test",
    fn(r) { renderer.enable_mouse(r, True) },
    fn(r, event) { handle_event(r, overlay_visible, status, event) },
    fn(r) { register_hits(r, overlay_visible) },
    fn() { view(overlay_visible, status) },
  )
}

fn handle_event(
  renderer: ffi.Renderer,
  overlay_visible: state.BoolCell,
  status: state.IntCell,
  event: input.Event,
) -> Nil {
  case event {
    input.MouseEvent(input.MouseData(action:, button:, x:, y:, ..)) ->
      case action, button {
        input.MousePress, input.LeftButton -> {
          let hit = input.hit_at(renderer, x, y)
          state.set_int(status, hit)
          case hit == overlay_hit, hit == button_hit {
            True, _ -> state.set_bool(overlay_visible, False)
            False, True -> state.set_bool(overlay_visible, True)
            False, False -> Nil
          }
        }
        _, _ -> Nil
      }
    _ -> Nil
  }
}

fn register_hits(renderer: ffi.Renderer, overlay_visible: state.BoolCell) -> Nil {
  input.clear_hit_grid(renderer)
  input.add_hit_region(renderer, 4, 6, 42, 12, 1)
  case state.get_bool(overlay_visible) {
    True -> {
      input.add_hit_region(
        renderer,
        0,
        0,
        common.term_w,
        common.term_h,
        overlay_hit,
      )
      input.add_hit_region(renderer, 18, 7, 40, 10, dialog_hit)
      input.add_hit_region(renderer, 30, 13, 16, 1, button_hit)
    }
    False -> Nil
  }
}

fn view(
  overlay_visible: state.BoolCell,
  status: state.IntCell,
) -> List(ui.Element) {
  let shown = state.get_bool(overlay_visible)

  [
    common.panel("Base scrollbox", 2, 3, 46, 18, [
      ui.Column([ui.Gap(1)], [
        common.line("Underlying content remains present."),
        common.line("Overlay hit id wins while visible."),
        common.line("Last hit: " <> status_label(state.get_int(status))),
      ]),
    ]),
    common.panel("Overlay state", 52, 3, 26, 18, [
      ui.Column([ui.Gap(1)], [
        common.line("Visible: " <> bool_label(shown)),
        common.line("Click dim layer to dismiss"),
        common.line("Click dialog button to show"),
      ]),
    ]),
    ..overlay_elements(shown)
  ]
}

fn overlay_elements(shown: Bool) -> List(ui.Element) {
  case shown {
    True -> [
      common.panel_with_background(
        "Overlay",
        18,
        7,
        40,
        10,
        common.accent_pink,
        [
          ui.Column([ui.Gap(1)], [
            common.line_with(
              [ui.Attributes(1)],
              "Dialog region sits above the dimmer hit area.",
            ),
            common.paragraph(
              "This freezes overlay hit precedence with the new runtime hit-grid wrappers: the outer layer dismisses, while the inner button keeps the overlay alive.",
            ),
            common.line_with(
              [
                ui.Foreground(common.color(common.bg_color)),
                ui.Background(common.color(common.accent_yellow)),
                ui.Attributes(1),
              ],
              "Show / keep overlay",
            ),
          ]),
        ],
      ),
    ]
    False -> []
  }
}

fn status_label(value: Int) -> String {
  case value {
    0 -> "0"
    1 -> "1"
    100 -> "100"
    200 -> "200"
    _ -> "201"
  }
}

fn bool_label(value: Bool) -> String {
  case value {
    True -> "yes"
    False -> "no"
  }
}
