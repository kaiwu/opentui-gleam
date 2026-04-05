import gleam/int
import gleam/string
import opentui/ffi
import opentui/runtime

pub type Parser

@external(javascript, "./input_parser.js", "createParser")
pub fn create_parser() -> Parser

@external(javascript, "./input_parser.js", "consumeChunk")
fn consume_chunk(
  parser: Parser,
  chunk: String,
  on_token: fn(String) -> Nil,
) -> Nil

@external(javascript, "./input_parser.js", "pushChunkJoined")
pub fn push_chunk(parser: Parser, chunk: String) -> String

pub type Event {
  KeyEvent(raw: String, key: Key)
  MouseEvent(MouseData)
  UnknownEvent(String)
}

pub type Key {
  ArrowUp
  ArrowDown
  ArrowLeft
  ArrowRight
  Enter
  Tab
  ShiftTab
  Home
  End
  Backspace
  Escape
  Character(String)
  UnknownKey(String)
}

pub type MouseAction {
  MousePress
  MouseRelease
  MouseDrag
  MouseScroll
}

pub type MouseButton {
  LeftButton
  MiddleButton
  RightButton
  WheelUp
  WheelDown
  NoButton
  OtherButton(Int)
}

pub type MouseData {
  MouseData(
    action: MouseAction,
    button: MouseButton,
    x: Int,
    y: Int,
    shift: Bool,
    alt: Bool,
    ctrl: Bool,
  )
}

pub fn run_event_loop(
  renderer: ffi.Renderer,
  on_event: fn(Event) -> Nil,
  draw_fn: fn() -> Nil,
) -> Nil {
  let parser = create_parser()

  runtime.run_raw_input_loop(
    ffi.renderer_to_int(renderer),
    fn(chunk) {
      consume_chunk(parser, chunk, fn(raw) { on_event(parse_event(raw)) })
    },
    draw_fn,
  )
}

pub fn parse_event(raw: String) -> Event {
  case string.starts_with(raw, "\u{1b}[<") {
    True ->
      case parse_mouse_event(raw) {
        Ok(event) -> MouseEvent(event)
        Error(_) -> UnknownEvent(raw)
      }
    False -> KeyEvent(raw, parse_key(raw))
  }
}

pub fn parse_key(raw: String) -> Key {
  case raw {
    "\u{1b}[A" -> ArrowUp
    "\u{1b}[B" -> ArrowDown
    "\u{1b}[C" -> ArrowRight
    "\u{1b}[D" -> ArrowLeft
    "\u{1b}[H" | "\u{1b}[1~" -> Home
    "\u{1b}[F" | "\u{1b}[4~" -> End
    "\u{1b}[Z" -> ShiftTab
    "\r" | "\n" -> Enter
    "\t" -> Tab
    "\u{7f}" | "\u{8}" -> Backspace
    "\u{1b}" -> Escape
    _ ->
      case string.length(raw) == 1 {
        True -> Character(raw)
        False -> UnknownKey(raw)
      }
  }
}

pub fn clear_hit_grid(renderer: ffi.Renderer) -> Nil {
  ffi.clear_current_hit_grid(ffi.renderer_to_int(renderer))
}

pub fn add_hit_region(
  renderer: ffi.Renderer,
  x: Int,
  y: Int,
  width: Int,
  height: Int,
  value: Int,
) -> Nil {
  ffi.add_to_hit_grid(ffi.renderer_to_int(renderer), x, y, width, height, value)
}

pub fn hit_at(renderer: ffi.Renderer, x: Int, y: Int) -> Int {
  ffi.check_hit(ffi.renderer_to_int(renderer), x, y)
}

fn parse_mouse_event(raw: String) -> Result(MouseData, Nil) {
  let length = string.length(raw)
  let suffix = string.slice(raw, length - 1, 1)
  let body = string.slice(raw, 3, length - 4)

  case string.split(body, ";") {
    [cb_raw, x_raw, y_raw] ->
      case int.parse(cb_raw), int.parse(x_raw), int.parse(y_raw) {
        Ok(cb), Ok(x), Ok(y) ->
          Ok(MouseData(
            action: mouse_action(cb, suffix),
            button: mouse_button(cb),
            x: x - 1,
            y: y - 1,
            shift: has_modifier(cb, 4),
            alt: has_modifier(cb, 8),
            ctrl: has_modifier(cb, 16),
          ))
        _, _, _ -> Error(Nil)
      }
    _ -> Error(Nil)
  }
}

fn mouse_action(cb: Int, suffix: String) -> MouseAction {
  case cb >= 64 {
    True -> MouseScroll
    False ->
      case suffix == "m" {
        True -> MouseRelease
        False ->
          case cb >= 32 {
            True -> MouseDrag
            False -> MousePress
          }
      }
  }
}

fn mouse_button(cb: Int) -> MouseButton {
  let code = cb % 4

  case cb >= 64, code {
    True, 0 -> WheelUp
    True, 1 -> WheelDown
    True, _ -> OtherButton(code)
    False, 0 -> LeftButton
    False, 1 -> MiddleButton
    False, 2 -> RightButton
    False, 3 -> NoButton
    False, _ -> OtherButton(code)
  }
}

fn has_modifier(cb: Int, bit: Int) -> Bool {
  cb / bit % 2 == 1
}
