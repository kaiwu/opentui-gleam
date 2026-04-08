import opentui/ffi

/// Register a callback that receives native log messages.
pub fn on_log(callback: fn(String) -> Nil) -> Nil {
  ffi.set_log_callback(callback)
}

/// Register a callback that receives native event strings.
pub fn on_event(callback: fn(String) -> Nil) -> Nil {
  ffi.set_event_callback(callback)
}
