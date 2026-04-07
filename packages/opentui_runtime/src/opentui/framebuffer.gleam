import gleam/string
import opentui/ffi
import opentui/types as core_types

/// Create a framebuffer (a buffer with alpha blending support).
pub fn create(
  width: Int,
  height: Int,
  id: String,
) -> Result(ffi.Buffer, String) {
  let ptr =
    ffi.create_buffer(
      width,
      height,
      True,
      core_types.width_method_to_int(core_types.Normal),
      id,
      string.byte_size(id),
    )
  case ptr {
    0 -> Error("Failed to create framebuffer")
    p -> Ok(ffi.buffer(p))
  }
}

/// Destroy a framebuffer.
pub fn destroy(fb: ffi.Buffer) -> Nil {
  ffi.destroy_frame_buffer(ffi.buffer_to_int(fb))
}

/// Blit the entire source framebuffer onto target at (dest_x, dest_y).
pub fn draw_onto(
  target: ffi.Buffer,
  dest_x: Int,
  dest_y: Int,
  source: ffi.Buffer,
) -> Nil {
  ffi.draw_frame_buffer(
    ffi.buffer_to_int(target),
    dest_x,
    dest_y,
    ffi.buffer_to_int(source),
    0,
    0,
    0,
    0,
  )
}

/// Blit a region of the source framebuffer onto target.
pub fn draw_region(
  target: ffi.Buffer,
  dest_x: Int,
  dest_y: Int,
  source: ffi.Buffer,
  src_x: Int,
  src_y: Int,
  w: Int,
  h: Int,
) -> Nil {
  ffi.draw_frame_buffer(
    ffi.buffer_to_int(target),
    dest_x,
    dest_y,
    ffi.buffer_to_int(source),
    src_x,
    src_y,
    w,
    h,
  )
}

/// Resize a framebuffer.
pub fn resize(fb: ffi.Buffer, width: Int, height: Int) -> Nil {
  ffi.buffer_resize(ffi.buffer_to_int(fb), width, height)
}

/// Get the width of a framebuffer.
pub fn width(fb: ffi.Buffer) -> Int {
  ffi.get_buffer_width(ffi.buffer_to_int(fb))
}

/// Get the height of a framebuffer.
pub fn height(fb: ffi.Buffer) -> Int {
  ffi.get_buffer_height(ffi.buffer_to_int(fb))
}
