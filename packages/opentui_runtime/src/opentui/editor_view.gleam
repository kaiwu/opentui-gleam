import opentui/ffi

pub fn create(buffer: ffi.EditBuffer, width: Int, height: Int) -> ffi.EditorView {
  ffi.editor_view(ffi.create_editor_view(
    ffi.edit_buffer_to_int(buffer),
    width,
    height,
  ))
}

pub fn destroy(view: ffi.EditorView) -> Nil {
  ffi.destroy_editor_view(ffi.editor_view_to_int(view))
}

pub fn set_viewport(
  view: ffi.EditorView,
  x: Int,
  y: Int,
  width: Int,
  height: Int,
  wrap: Bool,
) -> Nil {
  ffi.editor_view_set_viewport(
    ffi.editor_view_to_int(view),
    x,
    y,
    width,
    height,
    wrap,
  )
}

pub fn draw_to(buffer: ffi.Buffer, view: ffi.EditorView, x: Int, y: Int) -> Nil {
  ffi.buffer_draw_editor_view(
    ffi.buffer_to_int(buffer),
    ffi.editor_view_to_int(view),
    x,
    y,
  )
}
