// src/buffer.gleam
// Idiomatic Gleam API for buffer drawing operations

import gleam/string
import ffi
import types.{type WidthMethod}

pub fn create(
  width: Int,
  height: Int,
  respect_alpha: Bool,
  width_method: WidthMethod,
  id: String,
) -> Result(ffi.Buffer, String) {
  let ptr =
    ffi.create_buffer(
      width,
      height,
      respect_alpha,
      types.width_method_to_int(width_method),
      id,
      string.byte_size(id),
    )
  case ptr {
    0 -> Error("Failed to create buffer")
    p -> Ok(ffi.buffer(p))
  }
}

pub fn destroy(buffer: ffi.Buffer) -> Nil {
  ffi.destroy_buffer(ffi.buffer_to_int(buffer))
}

pub fn clear(buffer: ffi.Buffer, bg: #(Float, Float, Float, Float)) -> Nil {
  ffi.buffer_clear(ffi.buffer_to_int(buffer), rgba_to_list(bg))
}

pub fn draw_text(
  buffer: ffi.Buffer,
  text: String,
  x: Int,
  y: Int,
  fg: #(Float, Float, Float, Float),
  bg: #(Float, Float, Float, Float),
  attributes: Int,
) -> Nil {
  ffi.buffer_draw_text(
    ffi.buffer_to_int(buffer),
    text,
    string.byte_size(text),
    x,
    y,
    rgba_to_list(fg),
    rgba_to_list(bg),
    attributes,
  )
}

pub fn fill_rect(
  buffer: ffi.Buffer,
  x: Int,
  y: Int,
  width: Int,
  height: Int,
  bg: #(Float, Float, Float, Float),
) -> Nil {
  ffi.buffer_fill_rect(
    ffi.buffer_to_int(buffer),
    x,
    y,
    width,
    height,
    rgba_to_list(bg),
  )
}

pub fn set_cell(
  buffer: ffi.Buffer,
  x: Int,
  y: Int,
  char: Int,
  fg: #(Float, Float, Float, Float),
  bg: #(Float, Float, Float, Float),
  attributes: Int,
) -> Nil {
  ffi.buffer_set_cell(
    ffi.buffer_to_int(buffer),
    x,
    y,
    char,
    rgba_to_list(fg),
    rgba_to_list(bg),
    attributes,
  )
}

pub fn push_scissor_rect(
  buffer: ffi.Buffer,
  x: Int,
  y: Int,
  width: Int,
  height: Int,
) -> Nil {
  ffi.buffer_push_scissor_rect(ffi.buffer_to_int(buffer), x, y, width, height)
}

pub fn pop_scissor_rect(buffer: ffi.Buffer) -> Nil {
  ffi.buffer_pop_scissor_rect(ffi.buffer_to_int(buffer))
}

pub fn push_opacity(buffer: ffi.Buffer, opacity: Float) -> Nil {
  ffi.buffer_push_opacity(ffi.buffer_to_int(buffer), opacity)
}

pub fn pop_opacity(buffer: ffi.Buffer) -> Nil {
  ffi.buffer_pop_opacity(ffi.buffer_to_int(buffer))
}

pub fn get_next_buffer(renderer: ffi.Renderer) -> ffi.Buffer {
  ffi.buffer(ffi.get_next_buffer(ffi.renderer_to_int(renderer)))
}

// ── Internal helpers ──

fn rgba_to_list(c: #(Float, Float, Float, Float)) -> List(Float) {
  [c.0, c.1, c.2, c.3]
}
