import gleam/string
import opentui/ffi
import opentui/types

pub fn create(width_method: types.WidthMethod) -> ffi.TextBuffer {
  ffi.text_buffer(ffi.create_text_buffer(types.width_method_to_int(width_method)))
}

pub fn destroy(buffer: ffi.TextBuffer) -> Nil {
  ffi.destroy_text_buffer(ffi.text_buffer_to_int(buffer))
}

pub fn append(buffer: ffi.TextBuffer, text: String) -> Nil {
  ffi.text_buffer_append(
    ffi.text_buffer_to_int(buffer),
    text,
    string.byte_size(text),
  )
}

pub fn clear(buffer: ffi.TextBuffer) -> Nil {
  ffi.text_buffer_clear(ffi.text_buffer_to_int(buffer))
}

pub fn length(buffer: ffi.TextBuffer) -> Int {
  ffi.text_buffer_get_length(ffi.text_buffer_to_int(buffer))
}

pub fn text(buffer: ffi.TextBuffer) -> String {
  ffi.text_buffer_get_plain_text_as_string(ffi.text_buffer_to_int(buffer))
}
