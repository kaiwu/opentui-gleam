import gleam/string
import opentui/ffi

/// OSC 52 clipboard target.
pub type ClipboardTarget {
  /// System clipboard (c).
  SystemClipboard
  /// Primary selection (p), e.g. X11 primary.
  PrimarySelection
}

fn target_to_int(target: ClipboardTarget) -> Int {
  case target {
    SystemClipboard -> 99
    PrimarySelection -> 112
  }
}

/// Copy text to the terminal clipboard via OSC 52.
/// Returns True if the terminal accepted the sequence.
pub fn copy(target: ClipboardTarget, text: String) -> Bool {
  ffi.copy_to_clipboard_osc52(target_to_int(target), text, string.byte_size(text))
}
