import opentui/buffer
import opentui/ffi
import opentui/input
import opentui/renderer
import opentui/runtime

/// Configuration for an App.
pub type AppConfig {
  AppConfig(width: Int, height: Int, title: String, mouse: Bool)
}

pub fn default_config(title: String) -> AppConfig {
  AppConfig(width: 80, height: 24, title: title, mouse: False)
}

pub fn with_mouse(config: AppConfig, mouse: Bool) -> AppConfig {
  AppConfig(..config, mouse: mouse)
}

pub fn with_size(config: AppConfig, width: Int, height: Int) -> AppConfig {
  AppConfig(..config, width: width, height: height)
}

/// Run a static app: renders once, then re-renders on any keypress.
/// Exits on 'q' or Ctrl-C (handled by the native loop).
pub fn run_static(
  config: AppConfig,
  draw: fn(ffi.Renderer, ffi.Buffer) -> Nil,
) -> Nil {
  run_static_with_setup(config, fn(_renderer) { Nil }, draw)
}

pub fn run_static_with_setup(
  config: AppConfig,
  setup_renderer: fn(ffi.Renderer) -> Nil,
  draw: fn(ffi.Renderer, ffi.Buffer) -> Nil,
) -> Nil {
  let r = create_renderer(config)
  setup_renderer(r)
  runtime.run_demo_loop(r, fn() {
    let buf = buffer.get_next_buffer(r)
    draw(r, buf)
  })
  Nil
}

/// Run an interactive app driven by parsed input events.
pub fn run_interactive(
  config: AppConfig,
  on_event: fn(input.Event) -> Nil,
  draw: fn(ffi.Renderer, ffi.Buffer) -> Nil,
) -> Nil {
  run_interactive_with_setup(config, fn(_renderer) { Nil }, on_event, draw)
}

pub fn run_interactive_with_setup(
  config: AppConfig,
  setup_renderer: fn(ffi.Renderer) -> Nil,
  on_event: fn(input.Event) -> Nil,
  draw: fn(ffi.Renderer, ffi.Buffer) -> Nil,
) -> Nil {
  run_interactive_with_renderer_setup(
    config,
    setup_renderer,
    fn(_renderer, event) { on_event(event) },
    draw,
  )
}

pub fn run_interactive_with_renderer_setup(
  config: AppConfig,
  setup_renderer: fn(ffi.Renderer) -> Nil,
  on_event: fn(ffi.Renderer, input.Event) -> Nil,
  draw: fn(ffi.Renderer, ffi.Buffer) -> Nil,
) -> Nil {
  let r = create_renderer(config)
  setup_renderer(r)
  input.run_event_loop(r, fn(event) { on_event(r, event) }, fn() {
    let buf = buffer.get_next_buffer(r)
    draw(r, buf)
  })
  Nil
}

/// Run an animated app with a tick callback receiving delta time in ms.
pub fn run_animated(
  config: AppConfig,
  on_key: fn(String) -> Nil,
  on_tick: fn(Float) -> Nil,
  draw: fn(ffi.Renderer, ffi.Buffer) -> Nil,
) -> Nil {
  run_animated_with_setup(config, fn(_renderer) { Nil }, on_key, on_tick, draw)
}

pub fn run_animated_with_setup(
  config: AppConfig,
  setup_renderer: fn(ffi.Renderer) -> Nil,
  on_key: fn(String) -> Nil,
  on_tick: fn(Float) -> Nil,
  draw: fn(ffi.Renderer, ffi.Buffer) -> Nil,
) -> Nil {
  let r = create_renderer(config)
  setup_renderer(r)
  runtime.run_animated_loop(r, on_key, on_tick, fn() {
    let buf = buffer.get_next_buffer(r)
    draw(r, buf)
  })
  Nil
}

pub fn run_keyed(
  config: AppConfig,
  on_key: fn(String) -> Nil,
  draw: fn(ffi.Renderer, ffi.Buffer) -> Nil,
) -> Nil {
  run_keyed_with_setup(config, fn(_renderer) { Nil }, on_key, draw)
}

pub fn run_keyed_with_setup(
  config: AppConfig,
  setup_renderer: fn(ffi.Renderer) -> Nil,
  on_key: fn(String) -> Nil,
  draw: fn(ffi.Renderer, ffi.Buffer) -> Nil,
) -> Nil {
  run_interactive_with_renderer_setup(
    config,
    setup_renderer,
    fn(_renderer, event) {
      case key_from_event(event) {
        Ok(raw) -> on_key(raw)
        Error(_) -> Nil
      }
    },
    draw,
  )
}

pub fn key_from_event(event: input.Event) -> Result(String, Nil) {
  case event {
    input.KeyEvent(raw, _) -> Ok(raw)
    input.UnknownEvent(raw) -> Ok(raw)
    input.MouseEvent(_) -> Error(Nil)
  }
}

fn create_renderer(config: AppConfig) -> ffi.Renderer {
  let renderer_config =
    renderer.RendererConfig(
      width: config.width,
      height: config.height,
      screen_mode: renderer.AlternateScreen,
      exit_on_ctrl_c: True,
    )

  let r = case renderer.create(renderer_config) {
    Ok(r) -> r
    Error(msg) -> {
      runtime.log(msg)
      panic as "Failed to create renderer"
    }
  }

  renderer.setup(r, renderer.AlternateScreen)
  renderer.set_title(r, config.title)
  renderer.enable_mouse(r, config.mouse)
  r
}
