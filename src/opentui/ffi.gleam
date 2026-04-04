// Low-level @external declarations — raw FFI bindings to the native library.

pub opaque type Renderer {
  Renderer(Int)
}

pub opaque type Buffer {
  Buffer(Int)
}

pub opaque type TextBuffer {
  TextBuffer(Int)
}

pub opaque type EditBuffer {
  EditBuffer(Int)
}

pub opaque type EditorView {
  EditorView(Int)
}

pub opaque type SyntaxStyle {
  SyntaxStyle(Int)
}

pub fn renderer(ptr: Int) -> Renderer {
  Renderer(ptr)
}

pub fn renderer_to_int(r: Renderer) -> Int {
  case r {
    Renderer(ptr) -> ptr
  }
}

pub fn buffer(ptr: Int) -> Buffer {
  Buffer(ptr)
}

pub fn buffer_to_int(b: Buffer) -> Int {
  case b {
    Buffer(ptr) -> ptr
  }
}

pub fn text_buffer(ptr: Int) -> TextBuffer {
  TextBuffer(ptr)
}

pub fn text_buffer_to_int(b: TextBuffer) -> Int {
  case b {
    TextBuffer(ptr) -> ptr
  }
}

pub fn edit_buffer(ptr: Int) -> EditBuffer {
  EditBuffer(ptr)
}

pub fn edit_buffer_to_int(b: EditBuffer) -> Int {
  case b {
    EditBuffer(ptr) -> ptr
  }
}

pub fn editor_view(ptr: Int) -> EditorView {
  EditorView(ptr)
}

pub fn editor_view_to_int(v: EditorView) -> Int {
  case v {
    EditorView(ptr) -> ptr
  }
}

pub fn syntax_style(ptr: Int) -> SyntaxStyle {
  SyntaxStyle(ptr)
}

pub fn syntax_style_to_int(s: SyntaxStyle) -> Int {
  case s {
    SyntaxStyle(ptr) -> ptr
  }
}

@external(javascript, "./ffi_shim.js", "createRenderer")
pub fn create_renderer(
  width: Int,
  height: Int,
  testing: Bool,
  remote: Bool,
) -> Int

@external(javascript, "./ffi_shim.js", "destroyRenderer")
pub fn destroy_renderer(renderer: Int) -> Nil

@external(javascript, "./ffi_shim.js", "render")
pub fn render_frame(renderer: Int, force: Bool) -> Nil

@external(javascript, "./ffi_shim.js", "resizeRenderer")
pub fn resize_renderer(renderer: Int, width: Int, height: Int) -> Nil

@external(javascript, "./ffi_shim.js", "setupTerminal")
pub fn setup_terminal(renderer: Int, use_alternate_screen: Bool) -> Nil

@external(javascript, "./ffi_shim.js", "suspendRenderer")
pub fn suspend_renderer(renderer: Int) -> Nil

@external(javascript, "./ffi_shim.js", "resumeRenderer")
pub fn resume_renderer(renderer: Int) -> Nil

@external(javascript, "./ffi_shim.js", "createOptimizedBuffer")
pub fn create_buffer(
  width: Int,
  height: Int,
  respect_alpha: Bool,
  width_method: Int,
  id: String,
  id_len: Int,
) -> Int

@external(javascript, "./ffi_shim.js", "destroyOptimizedBuffer")
pub fn destroy_buffer(buffer: Int) -> Nil

@external(javascript, "./ffi_shim.js", "bufferClear")
pub fn buffer_clear(buffer: Int, bg: List(Float)) -> Nil

@external(javascript, "./ffi_shim.js", "bufferDrawText")
pub fn buffer_draw_text(
  buffer: Int,
  text: String,
  text_len: Int,
  x: Int,
  y: Int,
  fg: List(Float),
  bg: List(Float),
  attributes: Int,
) -> Nil

@external(javascript, "./ffi_shim.js", "bufferFillRect")
pub fn buffer_fill_rect(
  buffer: Int,
  x: Int,
  y: Int,
  width: Int,
  height: Int,
  bg: List(Float),
) -> Nil

@external(javascript, "./ffi_shim.js", "bufferSetCell")
pub fn buffer_set_cell(
  buffer: Int,
  x: Int,
  y: Int,
  char: Int,
  fg: List(Float),
  bg: List(Float),
  attributes: Int,
) -> Nil

@external(javascript, "./ffi_shim.js", "bufferPushScissorRect")
pub fn buffer_push_scissor_rect(
  buffer: Int,
  x: Int,
  y: Int,
  width: Int,
  height: Int,
) -> Nil

@external(javascript, "./ffi_shim.js", "bufferPopScissorRect")
pub fn buffer_pop_scissor_rect(buffer: Int) -> Nil

@external(javascript, "./ffi_shim.js", "bufferPushOpacity")
pub fn buffer_push_opacity(buffer: Int, opacity: Float) -> Nil

@external(javascript, "./ffi_shim.js", "bufferPopOpacity")
pub fn buffer_pop_opacity(buffer: Int) -> Nil

@external(javascript, "./ffi_shim.js", "getNextBuffer")
pub fn get_next_buffer(renderer: Int) -> Int

@external(javascript, "./ffi_shim.js", "setTerminalTitle")
pub fn set_terminal_title(renderer: Int, title: String, title_len: Int) -> Nil

@external(javascript, "./ffi_shim.js", "enableMouse")
pub fn enable_mouse(renderer: Int, enable_movement: Bool) -> Nil

@external(javascript, "./ffi_shim.js", "disableMouse")
pub fn disable_mouse(renderer: Int) -> Nil

@external(javascript, "./ffi_shim.js", "enableKittyKeyboard")
pub fn enable_kitty_keyboard(renderer: Int, flags: Int) -> Nil

@external(javascript, "./ffi_shim.js", "disableKittyKeyboard")
pub fn disable_kitty_keyboard(renderer: Int) -> Nil

@external(javascript, "./ffi_shim.js", "setCursorPosition")
pub fn set_cursor_position(renderer: Int, x: Int, y: Int, visible: Bool) -> Nil

@external(javascript, "./ffi_shim.js", "copyToClipboardOSC52")
pub fn copy_to_clipboard_osc52(
  target: Int,
  payload: String,
  payload_len: Int,
) -> Bool

@external(javascript, "./ffi_shim.js", "addToHitGrid")
pub fn add_to_hit_grid(
  renderer: Int,
  x: Int,
  y: Int,
  width: Int,
  height: Int,
  value: Int,
) -> Nil

@external(javascript, "./ffi_shim.js", "clearCurrentHitGrid")
pub fn clear_current_hit_grid(renderer: Int) -> Nil

@external(javascript, "./ffi_shim.js", "checkHit")
pub fn check_hit(renderer: Int, x: Int, y: Int) -> Int

@external(javascript, "./ffi_shim.js", "createTextBuffer")
pub fn create_text_buffer(width_method: Int) -> Int

@external(javascript, "./ffi_shim.js", "destroyTextBuffer")
pub fn destroy_text_buffer(buffer: Int) -> Nil

@external(javascript, "./ffi_shim.js", "textBufferAppend")
pub fn text_buffer_append(buffer: Int, text: String, text_len: Int) -> Nil

@external(javascript, "./ffi_shim.js", "textBufferClear")
pub fn text_buffer_clear(buffer: Int) -> Nil

@external(javascript, "./ffi_shim.js", "textBufferGetLength")
pub fn text_buffer_get_length(buffer: Int) -> Int

@external(javascript, "./ffi_shim.js", "textBufferGetPlainText")
pub fn text_buffer_get_plain_text(buffer: Int, out: String, out_len: Int) -> Int

@external(javascript, "./ffi_shim.js", "createEditBuffer")
pub fn create_edit_buffer(width_method: Int) -> Int

@external(javascript, "./ffi_shim.js", "destroyEditBuffer")
pub fn destroy_edit_buffer(buffer: Int) -> Nil

@external(javascript, "./ffi_shim.js", "editBufferSetText")
pub fn edit_buffer_set_text(buffer: Int, text: String, text_len: Int) -> Nil

@external(javascript, "./ffi_shim.js", "editBufferInsertText")
pub fn edit_buffer_insert_text(buffer: Int, text: String, text_len: Int) -> Nil

@external(javascript, "./ffi_shim.js", "editBufferGetText")
pub fn edit_buffer_get_text(buffer: Int, out: String, out_len: Int) -> Int

@external(javascript, "./ffi_shim.js", "editBufferGetTextAsString")
pub fn edit_buffer_get_text_as_string(buffer: Int) -> String

@external(javascript, "./ffi_shim.js", "editBufferUndo")
pub fn edit_buffer_undo(buffer: Int, out: String, out_len: Int) -> Int

@external(javascript, "./ffi_shim.js", "editBufferRedo")
pub fn edit_buffer_redo(buffer: Int, out: String, out_len: Int) -> Int

@external(javascript, "./ffi_shim.js", "editBufferCanUndo")
pub fn edit_buffer_can_undo(buffer: Int) -> Bool

@external(javascript, "./ffi_shim.js", "editBufferCanRedo")
pub fn edit_buffer_can_redo(buffer: Int) -> Bool

@external(javascript, "./ffi_shim.js", "editBufferInsertChar")
pub fn edit_buffer_insert_char(buffer: Int, text: String, text_len: Int) -> Nil

@external(javascript, "./ffi_shim.js", "editBufferDeleteCharBackward")
pub fn edit_buffer_delete_char_backward(buffer: Int) -> Nil

@external(javascript, "./ffi_shim.js", "editBufferDeleteChar")
pub fn edit_buffer_delete_char(buffer: Int) -> Nil

@external(javascript, "./ffi_shim.js", "editBufferMoveCursorLeft")
pub fn edit_buffer_move_cursor_left(buffer: Int) -> Nil

@external(javascript, "./ffi_shim.js", "editBufferMoveCursorRight")
pub fn edit_buffer_move_cursor_right(buffer: Int) -> Nil

@external(javascript, "./ffi_shim.js", "editBufferMoveCursorUp")
pub fn edit_buffer_move_cursor_up(buffer: Int) -> Nil

@external(javascript, "./ffi_shim.js", "editBufferMoveCursorDown")
pub fn edit_buffer_move_cursor_down(buffer: Int) -> Nil

@external(javascript, "./ffi_shim.js", "editBufferNewLine")
pub fn edit_buffer_new_line(buffer: Int) -> Nil

@external(javascript, "./ffi_shim.js", "editBufferGetCursor")
pub fn edit_buffer_get_cursor(buffer: Int) -> #(Int, Int)

@external(javascript, "./ffi_shim.js", "createEditorView")
pub fn create_editor_view(buffer: Int) -> Int

@external(javascript, "./ffi_shim.js", "destroyEditorView")
pub fn destroy_editor_view(view: Int) -> Nil

@external(javascript, "./ffi_shim.js", "editorViewSetViewport")
pub fn editor_view_set_viewport(
  view: Int,
  x: Int,
  y: Int,
  width: Int,
  height: Int,
  wrap: Bool,
) -> Nil

@external(javascript, "./ffi_shim.js", "bufferDrawEditorView")
pub fn buffer_draw_editor_view(buffer: Int, view: Int, x: Int, y: Int) -> Nil

@external(javascript, "./ffi_shim.js", "createSyntaxStyle")
pub fn create_syntax_style() -> Int

@external(javascript, "./ffi_shim.js", "destroySyntaxStyle")
pub fn destroy_syntax_style(style: Int) -> Nil

@external(javascript, "./ffi_shim.js", "syntaxStyleRegister")
pub fn syntax_style_register(
  style: Int,
  name: String,
  name_len: Int,
  fg: List(Float),
  bg: List(Float),
  attributes: Int,
) -> Int

@external(javascript, "./ffi_shim.js", "setLogCallback")
pub fn set_log_callback(callback: fn(String) -> Nil) -> Nil

@external(javascript, "./ffi_shim.js", "setEventCallback")
pub fn set_event_callback(callback: fn(String) -> Nil) -> Nil
