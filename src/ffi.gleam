// src/ffi.gleam
// Low-level @external declarations — raw FFI bindings to OpenTUI native library

// ── Opaque Handle Types ──

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

// ── Wrap/Unwrap ──

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

// ── Renderer Lifecycle ──

@external(javascript, "./priv/ffi-shim.js", "createRenderer")
pub fn create_renderer(
  width: Int,
  height: Int,
  testing: Bool,
  remote: Bool,
) -> Int

@external(javascript, "./priv/ffi-shim.js", "destroyRenderer")
pub fn destroy_renderer(renderer: Int) -> Nil

@external(javascript, "./priv/ffi-shim.js", "render")
pub fn render_frame(renderer: Int, force: Bool) -> Nil

@external(javascript, "./priv/ffi-shim.js", "resizeRenderer")
pub fn resize_renderer(renderer: Int, width: Int, height: Int) -> Nil

@external(javascript, "./priv/ffi-shim.js", "setupTerminal")
pub fn setup_terminal(renderer: Int, use_alternate_screen: Bool) -> Nil

@external(javascript, "./priv/ffi-shim.js", "suspendRenderer")
pub fn suspend_renderer(renderer: Int) -> Nil

@external(javascript, "./priv/ffi-shim.js", "resumeRenderer")
pub fn resume_renderer(renderer: Int) -> Nil

// ── Buffer ──

@external(javascript, "./priv/ffi-shim.js", "createOptimizedBuffer")
pub fn create_buffer(
  width: Int,
  height: Int,
  respect_alpha: Bool,
  width_method: Int,
  id: String,
  id_len: Int,
) -> Int

@external(javascript, "./priv/ffi-shim.js", "destroyOptimizedBuffer")
pub fn destroy_buffer(buffer: Int) -> Nil

@external(javascript, "./priv/ffi-shim.js", "bufferClear")
pub fn buffer_clear(buffer: Int, bg: List(Float)) -> Nil

@external(javascript, "./priv/ffi-shim.js", "bufferDrawText")
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

@external(javascript, "./priv/ffi-shim.js", "bufferFillRect")
pub fn buffer_fill_rect(
  buffer: Int,
  x: Int,
  y: Int,
  width: Int,
  height: Int,
  bg: List(Float),
) -> Nil

@external(javascript, "./priv/ffi-shim.js", "bufferSetCell")
pub fn buffer_set_cell(
  buffer: Int,
  x: Int,
  y: Int,
  char: Int,
  fg: List(Float),
  bg: List(Float),
  attributes: Int,
) -> Nil

@external(javascript, "./priv/ffi-shim.js", "bufferPushScissorRect")
pub fn buffer_push_scissor_rect(
  buffer: Int,
  x: Int,
  y: Int,
  width: Int,
  height: Int,
) -> Nil

@external(javascript, "./priv/ffi-shim.js", "bufferPopScissorRect")
pub fn buffer_pop_scissor_rect(buffer: Int) -> Nil

@external(javascript, "./priv/ffi-shim.js", "bufferPushOpacity")
pub fn buffer_push_opacity(buffer: Int, opacity: Float) -> Nil

@external(javascript, "./priv/ffi-shim.js", "bufferPopOpacity")
pub fn buffer_pop_opacity(buffer: Int) -> Nil

@external(javascript, "./priv/ffi-shim.js", "getNextBuffer")
pub fn get_next_buffer(renderer: Int) -> Int

// ── Terminal ──

@external(javascript, "./priv/ffi-shim.js", "setTerminalTitle")
pub fn set_terminal_title(renderer: Int, title: String, title_len: Int) -> Nil

@external(javascript, "./priv/ffi-shim.js", "enableMouse")
pub fn enable_mouse(renderer: Int, enable_movement: Bool) -> Nil

@external(javascript, "./priv/ffi-shim.js", "disableMouse")
pub fn disable_mouse(renderer: Int) -> Nil

@external(javascript, "./priv/ffi-shim.js", "enableKittyKeyboard")
pub fn enable_kitty_keyboard(renderer: Int, flags: Int) -> Nil

@external(javascript, "./priv/ffi-shim.js", "disableKittyKeyboard")
pub fn disable_kitty_keyboard(renderer: Int) -> Nil

@external(javascript, "./priv/ffi-shim.js", "setCursorPosition")
pub fn set_cursor_position(renderer: Int, x: Int, y: Int, visible: Bool) -> Nil

@external(javascript, "./priv/ffi-shim.js", "copyToClipboardOSC52")
pub fn copy_to_clipboard_osc52(clipboard_type: Int, text: String, text_len: Int) -> Bool

// ── Hit Grid (Mouse) ──

@external(javascript, "./priv/ffi-shim.js", "addToHitGrid")
pub fn add_to_hit_grid(
  renderer: Int,
  x: Int,
  y: Int,
  width: Int,
  height: Int,
  id: Int,
) -> Nil

@external(javascript, "./priv/ffi-shim.js", "clearCurrentHitGrid")
pub fn clear_hit_grid(renderer: Int) -> Nil

@external(javascript, "./priv/ffi-shim.js", "checkHit")
pub fn check_hit(renderer: Int, x: Int, y: Int) -> Int

// ── TextBuffer ──

@external(javascript, "./priv/ffi-shim.js", "createTextBuffer")
pub fn create_text_buffer(buffer_type: Int) -> Int

@external(javascript, "./priv/ffi-shim.js", "destroyTextBuffer")
pub fn destroy_text_buffer(buffer: Int) -> Nil

@external(javascript, "./priv/ffi-shim.js", "textBufferAppend")
pub fn text_buffer_append(buffer: Int, text: String, text_len: Int) -> Nil

@external(javascript, "./priv/ffi-shim.js", "textBufferClear")
pub fn text_buffer_clear(buffer: Int) -> Nil

@external(javascript, "./priv/ffi-shim.js", "textBufferGetLength")
pub fn text_buffer_get_length(buffer: Int) -> Int

@external(javascript, "./priv/ffi-shim.js", "textBufferGetPlainText")
pub fn text_buffer_get_plain_text(buffer: Int, output: String, output_len: Int) -> Int

// ── EditBuffer ──

@external(javascript, "./priv/ffi-shim.js", "createEditBuffer")
pub fn create_edit_buffer(buffer_type: Int) -> Int

@external(javascript, "./priv/ffi-shim.js", "destroyEditBuffer")
pub fn destroy_edit_buffer(buffer: Int) -> Nil

@external(javascript, "./priv/ffi-shim.js", "editBufferSetText")
pub fn edit_buffer_set_text(buffer: Int, text: String, text_len: Int) -> Nil

@external(javascript, "./priv/ffi-shim.js", "editBufferInsertText")
pub fn edit_buffer_insert_text(buffer: Int, text: String, text_len: Int) -> Nil

@external(javascript, "./priv/ffi-shim.js", "editBufferGetText")
pub fn edit_buffer_get_text(buffer: Int, output: String, output_len: Int) -> Int

@external(javascript, "./priv/ffi-shim.js", "editBufferGetTextAsString")
pub fn edit_buffer_get_text_as_string(buffer: Int) -> String

@external(javascript, "./priv/ffi-shim.js", "editBufferUndo")
pub fn edit_buffer_undo(buffer: Int, output: String, output_len: Int) -> Int

@external(javascript, "./priv/ffi-shim.js", "editBufferRedo")
pub fn edit_buffer_redo(buffer: Int, output: String, output_len: Int) -> Int

@external(javascript, "./priv/ffi-shim.js", "editBufferCanUndo")
pub fn edit_buffer_can_undo(buffer: Int) -> Bool

@external(javascript, "./priv/ffi-shim.js", "editBufferCanRedo")
pub fn edit_buffer_can_redo(buffer: Int) -> Bool

@external(javascript, "./priv/ffi-shim.js", "editBufferInsertChar")
pub fn edit_buffer_insert_char(buffer: Int, char: String, char_len: Int) -> Nil

@external(javascript, "./priv/ffi-shim.js", "editBufferDeleteCharBackward")
pub fn edit_buffer_delete_char_backward(buffer: Int) -> Nil

@external(javascript, "./priv/ffi-shim.js", "editBufferDeleteChar")
pub fn edit_buffer_delete_char(buffer: Int) -> Nil

@external(javascript, "./priv/ffi-shim.js", "editBufferMoveCursorLeft")
pub fn edit_buffer_move_cursor_left(buffer: Int) -> Nil

@external(javascript, "./priv/ffi-shim.js", "editBufferMoveCursorRight")
pub fn edit_buffer_move_cursor_right(buffer: Int) -> Nil

@external(javascript, "./priv/ffi-shim.js", "editBufferMoveCursorUp")
pub fn edit_buffer_move_cursor_up(buffer: Int) -> Nil

@external(javascript, "./priv/ffi-shim.js", "editBufferMoveCursorDown")
pub fn edit_buffer_move_cursor_down(buffer: Int) -> Nil

@external(javascript, "./priv/ffi-shim.js", "editBufferNewLine")
pub fn edit_buffer_new_line(buffer: Int) -> Nil

@external(javascript, "./priv/ffi-shim.js", "editBufferGetCursor")
pub fn edit_buffer_get_cursor(buffer: Int) -> #(Int, Int)

// ── EditorView ──

@external(javascript, "./priv/ffi-shim.js", "createEditorView")
pub fn create_editor_view(edit_buffer: Int, width: Int, height: Int) -> Int

@external(javascript, "./priv/ffi-shim.js", "destroyEditorView")
pub fn destroy_editor_view(view: Int) -> Nil

@external(javascript, "./priv/ffi-shim.js", "editorViewSetViewport")
pub fn editor_view_set_viewport(
  view: Int,
  x: Int,
  y: Int,
  width: Int,
  height: Int,
  wrap: Bool,
) -> Nil

@external(javascript, "./priv/ffi-shim.js", "bufferDrawEditorView")
pub fn buffer_draw_editor_view(buffer: Int, view: Int, x: Int, y: Int) -> Nil

// ── SyntaxStyle ──

@external(javascript, "./priv/ffi-shim.js", "createSyntaxStyle")
pub fn create_syntax_style() -> Int

@external(javascript, "./priv/ffi-shim.js", "destroySyntaxStyle")
pub fn destroy_syntax_style(style: Int) -> Nil

@external(javascript, "./priv/ffi-shim.js", "syntaxStyleRegister")
pub fn syntax_style_register(
  style: Int,
  name: String,
  name_len: Int,
  fg: List(Float),
  bg: List(Float),
  attributes: Int,
) -> Int

// ── Callbacks ──

@external(javascript, "./priv/ffi-shim.js", "setLogCallback")
pub fn set_log_callback(callback: fn(String) -> Nil) -> Nil

@external(javascript, "./priv/ffi-shim.js", "setEventCallback")
pub fn set_event_callback(callback: fn(String) -> Nil) -> Nil

// ── Demo Helpers (JS-side) ──

@external(javascript, "./priv/ffi-shim.js", "log")
pub fn log(msg: String) -> Nil

@external(javascript, "./priv/ffi-shim.js", "runDemoLoop")
pub fn run_demo_loop(renderer: Int, draw_fn: fn() -> Nil) -> Nil

@external(javascript, "./priv/ffi-shim.js", "runEditorLoop")
pub fn run_editor_loop(
  renderer: Int,
  on_key: fn(String) -> Nil,
  draw_fn: fn() -> Nil,
) -> Nil
