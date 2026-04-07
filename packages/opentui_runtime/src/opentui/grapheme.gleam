import gleam/string
import opentui/buffer
import opentui/ffi
import opentui/types as core_types

pub type EncodedChar {
  EncodedChar(codepoint: Int, width: Int)
}

/// Encode text into grapheme entries with display widths.
pub fn encode(
  text: String,
  method: core_types.WidthMethod,
) -> List(EncodedChar) {
  let wm = core_types.width_method_to_int(method)
  let len = ffi.encode_unicode_length(text, string.byte_size(text), wm)
  collect_encoded(0, len, [])
}

/// Calculate the total display width of a string.
pub fn display_width(text: String, method: core_types.WidthMethod) -> Int {
  let chars = encode(text, method)
  sum_widths(chars, 0)
}

/// Draw encoded graphemes onto a buffer at (x, y), returns the total width drawn.
pub fn draw_graphemes(
  buf: ffi.Buffer,
  chars: List(EncodedChar),
  x: Int,
  y: Int,
  fg: #(Float, Float, Float, Float),
  bg: #(Float, Float, Float, Float),
) -> Int {
  draw_loop(buf, chars, x, y, fg, bg, 0)
}

fn collect_encoded(i: Int, len: Int, acc: List(EncodedChar)) -> List(EncodedChar) {
  case i >= len {
    True -> reverse(acc, [])
    False -> {
      let cp = ffi.encode_unicode_char_at(i)
      let w = ffi.encode_unicode_width_at(i)
      collect_encoded(i + 1, len, [EncodedChar(cp, w), ..acc])
    }
  }
}

fn reverse(items: List(a), acc: List(a)) -> List(a) {
  case items {
    [] -> acc
    [first, ..rest] -> reverse(rest, [first, ..acc])
  }
}

fn sum_widths(chars: List(EncodedChar), acc: Int) -> Int {
  case chars {
    [] -> acc
    [c, ..rest] -> sum_widths(rest, acc + c.width)
  }
}

fn draw_loop(
  buf: ffi.Buffer,
  chars: List(EncodedChar),
  x: Int,
  y: Int,
  fg: #(Float, Float, Float, Float),
  bg: #(Float, Float, Float, Float),
  drawn: Int,
) -> Int {
  case chars {
    [] -> drawn
    [c, ..rest] -> {
      buffer.set_cell(buf, x + drawn, y, c.codepoint, fg, bg, 0)
      draw_loop(buf, rest, x, y, fg, bg, drawn + c.width)
    }
  }
}
