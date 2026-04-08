import opentui/callbacks

pub fn callbacks_module_exports_exist_test() {
  // The on_log and on_event functions require native FFI callback pointers
  // which can only be created at runtime with an active renderer.
  // Verify the module compiles and the functions are accessible.
  let _log_fn = callbacks.on_log
  let _event_fn = callbacks.on_event
  Nil
}
