import gleam/string
import opentui/ffi

pub fn create() -> ffi.SyntaxStyle {
  ffi.syntax_style(ffi.create_syntax_style())
}

pub fn destroy(style: ffi.SyntaxStyle) -> Nil {
  ffi.destroy_syntax_style(ffi.syntax_style_to_int(style))
}

pub fn register(
  style: ffi.SyntaxStyle,
  name: String,
  fg: #(Float, Float, Float, Float),
  bg: #(Float, Float, Float, Float),
  attributes: Int,
) -> Int {
  ffi.syntax_style_register(
    ffi.syntax_style_to_int(style),
    name,
    string.byte_size(name),
    [fg.0, fg.1, fg.2, fg.3],
    [bg.0, bg.1, bg.2, bg.3],
    attributes,
  )
}
