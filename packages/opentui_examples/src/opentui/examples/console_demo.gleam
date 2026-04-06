import gleam/int
import gleam/list
import gleam/string
import opentui/examples/common
import opentui/examples/phase2_model
import opentui/examples/phase2_state as state
import opentui/examples/phase3_model as model
import opentui/examples/phase3_state
import opentui/ffi
import opentui/input
import opentui/renderer
import opentui/ui

const debug_hit = 1

const info_hit = 2

const warn_hit = 3

const error_hit = 4

pub fn main() -> Nil {
  let log_text = phase3_state.create_string("")
  let log_count = state.create_int(0)
  let scroll = state.create_int(0)

  common.run_event_ui_demo_with_setup(
    "Console Demo",
    "Console Demo",
    fn(r) { renderer.enable_mouse(r, True) },
    fn(r, event) { handle_event(r, log_text, log_count, scroll, event) },
    register_hits,
    fn() { view(log_text, log_count, scroll) },
  )
}

fn handle_event(
  renderer: ffi.Renderer,
  log_text: phase3_state.StringCell,
  log_count: state.IntCell,
  scroll: state.IntCell,
  event: input.Event,
) -> Nil {
  case event {
    input.MouseEvent(input.MouseData(action:, button:, x:, y:, ..)) ->
      case action, button {
        input.MousePress, input.LeftButton -> {
          let hit = input.hit_at(renderer, x, y)
          case hit_to_level(hit) {
            Ok(l) -> {
              let n = state.get_int(log_count) + 1
              state.set_int(log_count, n)
              let entry = model.LogEntry(l, level_message(l, n))
              let line = model.format_entry(entry, n)
              phase3_state.set_string(
                log_text,
                phase2_model.append_log(
                  phase3_state.get_string(log_text),
                  line,
                  12,
                ),
              )
            }
            Error(_) -> Nil
          }
        }
        input.MouseScroll, input.WheelUp ->
          state.set_int(scroll, scroll_by(scroll, phase2_model.ArrowUp))
        input.MouseScroll, input.WheelDown ->
          state.set_int(scroll, scroll_by(scroll, phase2_model.ArrowDown))
        _, _ -> Nil
      }
    input.KeyEvent(_, key) ->
      case key {
        input.ArrowUp ->
          state.set_int(scroll, scroll_by(scroll, phase2_model.ArrowUp))
        input.ArrowDown ->
          state.set_int(scroll, scroll_by(scroll, phase2_model.ArrowDown))
        _ -> Nil
      }
    _ -> Nil
  }
}

fn scroll_by(scroll: state.IntCell, key: phase2_model.Key) -> Int {
  phase2_model.adjust_scroll(state.get_int(scroll), key, 12)
}

fn hit_to_level(hit: Int) -> Result(model.LogLevel, Nil) {
  case hit {
    1 -> Ok(model.Debug)
    2 -> Ok(model.Info)
    3 -> Ok(model.Warn)
    4 -> Ok(model.ErrorLevel)
    _ -> Error(Nil)
  }
}

fn register_hits(renderer: ffi.Renderer) -> Nil {
  input.clear_hit_grid(renderer)
  input.add_hit_region(renderer, 55, 5, 10, 1, debug_hit)
  input.add_hit_region(renderer, 67, 5, 8, 1, info_hit)
  input.add_hit_region(renderer, 55, 7, 10, 1, warn_hit)
  input.add_hit_region(renderer, 67, 7, 8, 1, error_hit)
}

fn view(
  log_text: phase3_state.StringCell,
  log_count: state.IntCell,
  _scroll: state.IntCell,
) -> List(ui.Element) {
  let text = phase3_state.get_string(log_text)
  let count = state.get_int(log_count)

  [
    common.panel("Log output", 2, 3, 50, 18, [
      ui.Column([ui.Gap(0)], log_lines(text)),
    ]),
    common.panel("Controls", 54, 3, 24, 18, [
      ui.Column([ui.Gap(1)], [
        common.line("Click to log:"),
        ui.Spacer(1),
        button_line("  DEBUG  ", common.accent_blue),
        button_line("  INFO   ", common.accent_green),
        ui.Spacer(1),
        button_line("  WARN   ", common.accent_orange),
        button_line("  ERROR  ", common.accent_pink),
        ui.Spacer(1),
        common.line("Total: " <> int.to_string(count)),
        ui.Spacer(1),
        common.paragraph(
          "Each button appends a styled log entry to a bounded FIFO buffer. Pure data model drives the view.",
        ),
      ]),
    ]),
  ]
}

fn button_line(
  label: String,
  bg: #(Float, Float, Float, Float),
) -> ui.Element {
  common.line_with(
    [
      ui.Foreground(common.color(common.bg_color)),
      ui.Background(common.color(bg)),
      ui.Attributes(1),
    ],
    label,
  )
}

fn log_lines(text: String) -> List(ui.Element) {
  case text {
    "" -> [
      common.line_with(
        [ui.Foreground(common.color(common.muted_fg))],
        "(no entries yet)",
      ),
    ]
    _ ->
      text
      |> string.split("\n")
      |> list.map(styled_log_line)
  }
}

fn styled_log_line(line: String) -> ui.Element {
  let color = case string.contains(line, "DEBUG") {
    True -> common.accent_blue
    False ->
      case string.contains(line, "INFO") {
        True -> common.accent_green
        False ->
          case string.contains(line, "WARN") {
            True -> common.accent_orange
            False ->
              case string.contains(line, "ERROR") {
                True -> common.accent_pink
                False -> common.fg_color
              }
          }
      }
  }
  common.line_with([ui.Foreground(common.color(color))], line)
}

fn level_message(level: model.LogLevel, n: Int) -> String {
  case level {
    model.Debug -> "debug trace #" <> int.to_string(n)
    model.Info -> "system ready (" <> int.to_string(n) <> ")"
    model.Warn -> "high latency warning #" <> int.to_string(n)
    model.ErrorLevel -> "connection failed #" <> int.to_string(n)
  }
}
