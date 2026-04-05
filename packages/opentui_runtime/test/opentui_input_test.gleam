import gleeunit/should
import opentui/input

pub fn parse_key_classifies_navigation_sequences_test() {
  let _ = input.parse_key("\u{1b}[A") |> should.equal(input.ArrowUp)
  let _ = input.parse_key("\u{1b}[F") |> should.equal(input.End)
  let _ = input.parse_key("\t") |> should.equal(input.Tab)
  input.parse_key("x") |> should.equal(input.Character("x"))
}

pub fn parse_event_decodes_mouse_press_test() {
  case input.parse_event("\u{1b}[<0;12;8M") {
    input.MouseEvent(input.MouseData(
      action:,
      button:,
      x:,
      y:,
      shift:,
      alt:,
      ctrl:,
    )) -> {
      let _ = action |> should.equal(input.MousePress)
      let _ = button |> should.equal(input.LeftButton)
      let _ = x |> should.equal(11)
      let _ = y |> should.equal(7)
      let _ = shift |> should.equal(False)
      let _ = alt |> should.equal(False)
      ctrl |> should.equal(False)
    }
    _ -> panic as "expected parsed mouse press"
  }
}

pub fn parse_event_decodes_wheel_and_modifiers_test() {
  case input.parse_event("\u{1b}[<68;20;4M") {
    input.MouseEvent(input.MouseData(
      action:,
      button:,
      x:,
      y:,
      shift:,
      alt:,
      ctrl:,
    )) -> {
      let _ = action |> should.equal(input.MouseScroll)
      let _ = button |> should.equal(input.WheelUp)
      let _ = x |> should.equal(19)
      let _ = y |> should.equal(3)
      let _ = shift |> should.equal(True)
      let _ = alt |> should.equal(False)
      ctrl |> should.equal(False)
    }
    _ -> panic as "expected parsed wheel event"
  }
}

pub fn parse_event_decodes_drag_and_release_test() {
  let drag = input.parse_event("\u{1b}[<32;9;3M")
  let release = input.parse_event("\u{1b}[<0;9;3m")

  let _ = case drag {
    input.MouseEvent(input.MouseData(action:, button:, x:, y:, ..)) -> {
      let _ = action |> should.equal(input.MouseDrag)
      let _ = button |> should.equal(input.LeftButton)
      let _ = x |> should.equal(8)
      y |> should.equal(2)
    }
    _ -> panic as "expected parsed drag event"
  }

  case release {
    input.MouseEvent(input.MouseData(action:, button:, x:, y:, ..)) -> {
      let _ = action |> should.equal(input.MouseRelease)
      let _ = button |> should.equal(input.LeftButton)
      let _ = x |> should.equal(8)
      y |> should.equal(2)
    }
    _ -> panic as "expected parsed release event"
  }
}

pub fn parse_event_keeps_unknown_sequences_test() {
  input.parse_event("\u{1b}[200~")
  |> should.equal(input.KeyEvent("\u{1b}[200~", input.UnknownKey("\u{1b}[200~")))
}

pub fn parser_preserves_split_mouse_sequences_test() {
  let parser = input.create_parser()
  let _ = input.push_chunk(parser, "\u{1b}[<0;12") |> should.equal("")

  input.push_chunk(parser, ";8M")
  |> should.equal("\u{1b}[<0;12;8M")
}
