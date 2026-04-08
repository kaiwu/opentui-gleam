import opentui/clipboard

pub fn clipboard_target_types_exist_test() {
  // Verify the type constructors compile and are distinct
  let _system = clipboard.SystemClipboard
  let _primary = clipboard.PrimarySelection
  Nil
}
