import gleeunit/should
import opentui/app
import opentui/input

pub fn app_config_constructs_test() {
  let config = app.AppConfig(width: 80, height: 24, title: "Test", mouse: False)
  let _ = config.width
  let _ = config.height
  let _ = config.title
  let _ = config.mouse
  Nil
}

pub fn default_config_sets_expected_defaults_test() {
  let config = app.default_config("Demo")
  let _ = config.width |> should.equal(80)
  let _ = config.height |> should.equal(24)
  let _ = config.title |> should.equal("Demo")
  config.mouse |> should.equal(False)
}

pub fn with_mouse_updates_mouse_flag_test() {
  let config = app.default_config("Demo") |> app.with_mouse(True)
  config.mouse |> should.equal(True)
}

pub fn with_size_updates_dimensions_test() {
  let config = app.default_config("Demo") |> app.with_size(100, 40)
  let _ = config.width |> should.equal(100)
  config.height |> should.equal(40)
}

pub fn key_from_event_returns_raw_key_for_key_events_test() {
  app.key_from_event(input.KeyEvent("x", input.Character("x")))
  |> should.equal(Ok("x"))
}

pub fn key_from_event_returns_raw_key_for_unknown_events_test() {
  app.key_from_event(input.UnknownEvent("\u{1b}[200~"))
  |> should.equal(Ok("\u{1b}[200~"))
}

pub fn key_from_event_ignores_mouse_events_test() {
  app.key_from_event(
    input.MouseEvent(input.MouseData(
      action: input.MousePress,
      button: input.LeftButton,
      x: 1,
      y: 2,
      shift: False,
      alt: False,
      ctrl: False,
    )),
  )
  |> should.equal(Error(Nil))
}

pub fn run_interactive_with_renderer_setup_is_exposed_test() {
  let fn_ref = app.run_interactive_with_renderer_setup
  let _ = fn_ref
  Nil
}
