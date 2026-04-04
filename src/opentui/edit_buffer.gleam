import gleam/string
import opentui/ffi

pub fn create(width_method: Int) -> ffi.EditBuffer {
  ffi.edit_buffer(ffi.create_edit_buffer(width_method))
}

pub fn set_text(buffer: ffi.EditBuffer, text: String) -> Nil {
  ffi.edit_buffer_set_text(
    ffi.edit_buffer_to_int(buffer),
    text,
    string.byte_size(text),
  )
}

pub fn text(buffer: ffi.EditBuffer) -> String {
  ffi.edit_buffer_get_text_as_string(ffi.edit_buffer_to_int(buffer))
}

pub fn insert_char(buffer: ffi.EditBuffer, text: String) -> Nil {
  ffi.edit_buffer_insert_char(
    ffi.edit_buffer_to_int(buffer),
    text,
    string.byte_size(text),
  )
}

pub fn delete_backward(buffer: ffi.EditBuffer) -> Nil {
  ffi.edit_buffer_delete_char_backward(ffi.edit_buffer_to_int(buffer))
}

pub fn move_left(buffer: ffi.EditBuffer) -> Nil {
  ffi.edit_buffer_move_cursor_left(ffi.edit_buffer_to_int(buffer))
}

pub fn move_right(buffer: ffi.EditBuffer) -> Nil {
  ffi.edit_buffer_move_cursor_right(ffi.edit_buffer_to_int(buffer))
}

pub fn move_up(buffer: ffi.EditBuffer) -> Nil {
  ffi.edit_buffer_move_cursor_up(ffi.edit_buffer_to_int(buffer))
}

pub fn move_down(buffer: ffi.EditBuffer) -> Nil {
  ffi.edit_buffer_move_cursor_down(ffi.edit_buffer_to_int(buffer))
}

pub fn new_line(buffer: ffi.EditBuffer) -> Nil {
  ffi.edit_buffer_new_line(ffi.edit_buffer_to_int(buffer))
}

pub fn cursor(buffer: ffi.EditBuffer) -> #(Int, Int) {
  ffi.edit_buffer_get_cursor(ffi.edit_buffer_to_int(buffer))
}
