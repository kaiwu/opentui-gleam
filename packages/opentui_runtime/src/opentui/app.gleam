import opentui/buffer
import opentui/ffi
import opentui/input
import opentui/renderer
import opentui/runtime

/// Configuration for an App.
pub type AppConfig {
  AppConfig(
    width: Int,
    height: Int,
    title: String,
    mouse: Bool,
  )
}

/// Run a static app: renders once, then re-renders on any keypress.
/// Exits on 'q' or Ctrl-C (handled by the native loop).
pub fn run_static(
  config: AppConfig,
  draw: fn(ffi.Renderer, ffi.Buffer) -> Nil,
) -> Nil {
  let r = create_renderer(config)
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
  let r = create_renderer(config)
  input.run_event_loop(r, on_event, fn() {
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
  let r = create_renderer(config)
  runtime.run_animated_loop(r, on_key, on_tick, fn() {
    let buf = buffer.get_next_buffer(r)
    draw(r, buf)
  })
  Nil
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
