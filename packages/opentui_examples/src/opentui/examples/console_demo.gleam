import gleam/int
import gleam/list
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
          let level = case hit {
            1 -> Ok(model.Debug)
            2 -> Ok(model.Info)
            3 -> Ok(model.Warn)
            4 -> Ok(model.ErrorLevel)
            _ -> Error(Nil)
          }
          case level {
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
          state.set_int(
            scroll,
            phase2_model.adjust_scroll(
              state.get_int(scroll),
              phase2_model.ArrowUp,
              12,
            ),
          )
        input.MouseScroll, input.WheelDown ->
          state.set_int(
            scroll,
            phase2_model.adjust_scroll(
              state.get_int(scroll),
              phase2_model.ArrowDown,
              12,
            ),
          )
        _, _ -> Nil
      }
    input.KeyEvent(_, key) ->
      case key {
        input.ArrowUp ->
          state.set_int(
            scroll,
            phase2_model.adjust_scroll(
              state.get_int(scroll),
              phase2_model.ArrowUp,
              12,
            ),
          )
        input.ArrowDown ->
          state.set_int(
            scroll,
            phase2_model.adjust_scroll(
              state.get_int(scroll),
              phase2_model.ArrowDown,
              12,
            ),
          )
        _ -> Nil
      }
    _ -> Nil
  }
}

fn register_hits(renderer: ffi.Renderer) -> Nil {
  input.clear_hit_grid(renderer)
  input.add_hit_region(renderer, 55, 5, 10, 1, debug_hit)
  input.add_hit_region(renderer, 66, 5, 10, 1, info_hit)
  input.add_hit_region(renderer, 55, 7, 10, 1, warn_hit)
  input.add_hit_region(renderer, 66, 7, 10, 1, error_hit)
}

fn view(
  log_text: phase3_state.StringCell,
  log_count: state.IntCell,
  scroll: state.IntCell,
) -> List(ui.Element) {
  let text = phase3_state.get_string(log_text)
  let count = state.get_int(log_count)
  let _offset = state.get_int(scroll)

  [
    common.panel("Log output", 2, 3, 50, 18, [
      ui.Column(
        [ui.Gap(0)],
        log_lines(text),
      ),
    ]),
    common.panel("Controls", 54, 3, 24, 18, [
      ui.Column([ui.Gap(1)], [
        common.line("Click to log:"),
        ui.Spacer(1),
        button_line("DEBUG", common.accent_blue),
        button_line("INFO", common.accent_green),
        ui.Spacer(1),
        button_line("WARN", common.accent_orange),
        button_line("ERROR", common.accent_pink),
        ui.Spacer(1),
        common.line("Total: " <> int.to_string(count)),
        ui.Spacer(1),
        common.paragraph(
          "Each button appends a styled log entry. The buffer keeps the last 12 lines. Pure data model — entries are formatted by phase3_model.",
        ),
      ]),
    ]),
  ]
}

fn button_line(label: String, color: #(Float, Float, Float, Float)) -> ui.Element {
  common.line_with(
    [
      ui.Foreground(common.color(common.bg_color)),
      ui.Background(common.color(color)),
      ui.Attributes(1),
    ],
    " " <> label <> " ",
  )
}

fn log_lines(text: String) -> List(ui.Element) {
  case text {
    "" -> [common.line_with([ui.Foreground(common.color(common.muted_fg))], "(no entries yet)")]
    _ ->
      text
      |> split_lines
      |> list.map(fn(line) { styled_log_line(line) })
  }
}

fn styled_log_line(line: String) -> ui.Element {
  let color = case True {
    _ if contains_level(line, "DEBUG") -> common.accent_blue
    _ if contains_level(line, "INFO") -> common.accent_green
    _ if contains_level(line, "WARN") -> common.accent_orange
    _ if contains_level(line, "ERROR") -> common.accent_pink
    _ -> common.fg_color
  }
  common.line_with([ui.Foreground(common.color(color))], line)
}

fn contains_level(line: String, level: String) -> Bool {
  case line {
    _ -> {
      let _ = level
      // simple substring check via the line prefix pattern
      case split_after_bracket(line) {
        Ok(rest) ->
          case starts_with_str(rest, level) {
            True -> True
            False -> False
          }
        Error(_) -> False
      }
    }
  }
}

fn split_after_bracket(line: String) -> Result(String, Nil) {
  case find_bracket_end(line, 0) {
    Ok(idx) -> Ok(drop_chars(line, idx))
    Error(_) -> Error(Nil)
  }
}

fn find_bracket_end(line: String, pos: Int) -> Result(Int, Nil) {
  case drop_chars(line, pos) {
    "" -> Error(Nil)
    rest ->
      case first_char(rest) {
        "]" -> Ok(pos + 2)
        _ -> find_bracket_end(line, pos + 1)
      }
  }
}

fn starts_with_str(text: String, prefix: String) -> Bool {
  case first_n_chars(text, char_count(prefix)) == prefix {
    True -> True
    False -> False
  }
}

fn first_char(s: String) -> String {
  case s {
    "" -> ""
    _ -> {
      let assert [c, ..] = to_graphemes(s)
      c
    }
  }
}

fn first_n_chars(s: String, n: Int) -> String {
  slice(s, 0, n)
}

fn char_count(s: String) -> Int {
  length(s)
}

fn drop_chars(s: String, n: Int) -> String {
  slice(s, n, length(s) - n)
}

fn split_lines(text: String) -> List(String) {
  split(text, "\n")
}

fn level_message(level: model.LogLevel, n: Int) -> String {
  case level {
    model.Debug -> "debug trace #" <> int.to_string(n)
    model.Info -> "system ready (" <> int.to_string(n) <> ")"
    model.Warn -> "high latency warning #" <> int.to_string(n)
    model.ErrorLevel -> "connection failed #" <> int.to_string(n)
  }
}

@external(javascript, "../../../gleam_stdlib/gleam/string.mjs", "split")
fn split(a: String, b: String) -> List(String)

@external(javascript, "../../../gleam_stdlib/gleam/string.mjs", "length")
fn length(a: String) -> Int

@external(javascript, "../../../gleam_stdlib/gleam/string.mjs", "slice")
fn slice(a: String, b: Int, c: Int) -> String

@external(javascript, "../../../gleam_stdlib/gleam/string.mjs", "to_graphemes")
fn to_graphemes(a: String) -> List(String)
