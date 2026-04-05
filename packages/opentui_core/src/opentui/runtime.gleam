@external(javascript, "./ffi_shim.js", "log")
pub fn log(msg: String) -> Nil

@external(javascript, "./ffi_shim.js", "runDemoLoop")
pub fn run_demo_loop(renderer: Int, draw_fn: fn() -> Nil) -> Nil

@external(javascript, "./ffi_shim.js", "runEditorLoop")
pub fn run_editor_loop(
  renderer: Int,
  on_key: fn(String) -> Nil,
  draw_fn: fn() -> Nil,
) -> Nil

@external(javascript, "./ffi_shim.js", "runEventLoop")
pub fn run_event_loop(
  renderer: Int,
  on_event: fn(String) -> Nil,
  draw_fn: fn() -> Nil,
) -> Nil

@external(javascript, "./ffi_shim.js", "runRawInputLoop")
pub fn run_raw_input_loop(
  renderer: Int,
  on_chunk: fn(String) -> Nil,
  draw_fn: fn() -> Nil,
) -> Nil
