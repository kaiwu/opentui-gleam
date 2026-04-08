import opentui/ffi

pub fn log(msg: String) -> Nil {
  ffi.log(msg)
}

pub fn run_demo_loop(renderer: ffi.Renderer, draw_fn: fn() -> Nil) -> Nil {
  ffi.run_demo_loop(ffi.renderer_to_int(renderer), draw_fn)
}

pub fn run_editor_loop(
  renderer: ffi.Renderer,
  on_key: fn(String) -> Nil,
  draw_fn: fn() -> Nil,
) -> Nil {
  ffi.run_editor_loop(ffi.renderer_to_int(renderer), on_key, draw_fn)
}

pub fn run_event_loop(
  renderer: ffi.Renderer,
  on_event: fn(String) -> Nil,
  draw_fn: fn() -> Nil,
) -> Nil {
  ffi.run_event_loop(ffi.renderer_to_int(renderer), on_event, draw_fn)
}

pub fn run_raw_input_loop(
  renderer: ffi.Renderer,
  on_chunk: fn(String) -> Nil,
  draw_fn: fn() -> Nil,
) -> Nil {
  ffi.run_raw_input_loop(ffi.renderer_to_int(renderer), on_chunk, draw_fn)
}

pub fn run_animated_loop(
  renderer: ffi.Renderer,
  on_key: fn(String) -> Nil,
  on_tick: fn(Float) -> Nil,
  draw_fn: fn() -> Nil,
) -> Nil {
  ffi.run_animated_loop(
    ffi.renderer_to_int(renderer),
    on_key,
    on_tick,
    draw_fn,
  )
}
