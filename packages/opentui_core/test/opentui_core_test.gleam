import gleeunit
import gleeunit/should
import opentui/ffi

pub fn main() {
  gleeunit.main()
}

pub fn renderer_lifecycle_smoke_test() {
  let ptr = ffi.create_renderer(80, 24, True, False)
  let _ = { ptr > 0 } |> should.equal(True)
  ffi.destroy_renderer(ptr)
}

pub fn buffer_lifecycle_smoke_test() {
  let ptr = ffi.create_buffer(20, 10, False, 0, "test", 4)
  let _ = { ptr > 0 } |> should.equal(True)
  ffi.buffer_clear(ptr, [0.0, 0.0, 0.0, 1.0])
  ffi.destroy_buffer(ptr)
}

pub fn text_buffer_append_and_length_test() {
  let ptr = ffi.create_text_buffer(0)
  let _ = ffi.text_buffer_get_length(ptr) |> should.equal(0)
  ffi.text_buffer_append(ptr, "hello", 5)
  let _ = { ffi.text_buffer_get_length(ptr) > 0 } |> should.equal(True)
  ffi.text_buffer_clear(ptr)
  let _ = ffi.text_buffer_get_length(ptr) |> should.equal(0)
  ffi.destroy_text_buffer(ptr)
}

pub fn text_buffer_get_plain_text_as_string_test() {
  let ptr = ffi.create_text_buffer(0)
  ffi.text_buffer_append(ptr, "gleam", 5)
  let content = ffi.text_buffer_get_plain_text_as_string(ptr)
  let _ = content |> should.equal("gleam")
  ffi.destroy_text_buffer(ptr)
}

pub fn edit_buffer_cursor_and_text_test() {
  let ptr = ffi.create_edit_buffer(0)
  ffi.edit_buffer_set_text(ptr, "ab", 2)
  let _ = ffi.edit_buffer_get_text_as_string(ptr) |> should.equal("ab")

  let #(row, col) = ffi.edit_buffer_get_cursor(ptr)
  let _ = row |> should.equal(0)
  let _ = { col >= 0 } |> should.equal(True)
  ffi.destroy_edit_buffer(ptr)
}

pub fn syntax_style_register_returns_id_test() {
  let ptr = ffi.create_syntax_style()
  let id =
    ffi.syntax_style_register(
      ptr,
      "keyword",
      7,
      [0.8, 0.2, 0.4, 1.0],
      [0.0, 0.0, 0.0, 1.0],
      1,
    )
  let _ = { id >= 0 } |> should.equal(True)
  ffi.destroy_syntax_style(ptr)
}

pub fn opaque_type_roundtrip_test() {
  let r = ffi.renderer(42)
  let _ = ffi.renderer_to_int(r) |> should.equal(42)

  let b = ffi.buffer(99)
  let _ = ffi.buffer_to_int(b) |> should.equal(99)

  let tb = ffi.text_buffer(7)
  let _ = ffi.text_buffer_to_int(tb) |> should.equal(7)

  let eb = ffi.edit_buffer(13)
  let _ = ffi.edit_buffer_to_int(eb) |> should.equal(13)

  let ev = ffi.editor_view(21)
  let _ = ffi.editor_view_to_int(ev) |> should.equal(21)

  let ss = ffi.syntax_style(55)
  ffi.syntax_style_to_int(ss) |> should.equal(55)
}
