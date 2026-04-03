// src/renderer.gleam
// Idiomatic Gleam API for renderer operations

import gleam/string
import ffi

pub type ScreenMode {
  AlternateScreen
  MainScreen
  SplitFooter(Int)
}

pub type RendererConfig {
  RendererConfig(
    width: Int,
    height: Int,
    screen_mode: ScreenMode,
    exit_on_ctrl_c: Bool,
  )
}

pub fn create(config: RendererConfig) -> Result(ffi.Renderer, String) {
  let ptr =
    ffi.create_renderer(config.width, config.height, False, False)
  case ptr {
    0 -> Error("Failed to create renderer")
    p -> Ok(ffi.renderer(p))
  }
}

pub fn destroy(renderer: ffi.Renderer) -> Nil {
  ffi.destroy_renderer(ffi.renderer_to_int(renderer))
}

pub fn render(renderer: ffi.Renderer, force: Bool) -> Nil {
  ffi.render_frame(ffi.renderer_to_int(renderer), force)
}

pub fn setup(renderer: ffi.Renderer, mode: ScreenMode) -> Nil {
  let use_alternate = case mode {
    AlternateScreen -> True
    _ -> False
  }
  ffi.setup_terminal(ffi.renderer_to_int(renderer), use_alternate)
}

pub fn resize(renderer: ffi.Renderer, width: Int, height: Int) -> Nil {
  ffi.resize_renderer(ffi.renderer_to_int(renderer), width, height)
}

pub fn suspend(renderer: ffi.Renderer) -> Nil {
  ffi.suspend_renderer(ffi.renderer_to_int(renderer))
}

pub fn resume(renderer: ffi.Renderer) -> Nil {
  ffi.resume_renderer(ffi.renderer_to_int(renderer))
}

pub fn set_title(renderer: ffi.Renderer, title: String) -> Nil {
  ffi.set_terminal_title(
    ffi.renderer_to_int(renderer),
    title,
    string.byte_size(title),
  )
}

pub fn enable_mouse(renderer: ffi.Renderer, enable_movement: Bool) -> Nil {
  ffi.enable_mouse(ffi.renderer_to_int(renderer), enable_movement)
}

pub fn disable_mouse(renderer: ffi.Renderer) -> Nil {
  ffi.disable_mouse(ffi.renderer_to_int(renderer))
}

pub fn enable_kitty_keyboard(renderer: ffi.Renderer, flags: Int) -> Nil {
  ffi.enable_kitty_keyboard(ffi.renderer_to_int(renderer), flags)
}

pub fn disable_kitty_keyboard(renderer: ffi.Renderer) -> Nil {
  ffi.disable_kitty_keyboard(ffi.renderer_to_int(renderer))
}

pub fn set_cursor_position(
  renderer: ffi.Renderer,
  x: Int,
  y: Int,
  visible: Bool,
) -> Nil {
  ffi.set_cursor_position(ffi.renderer_to_int(renderer), x, y, visible)
}
