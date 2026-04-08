import gleam/string
import opentui/ffi

/// Text attribute flags for syntax style registration.
pub const attr_none = 0

pub const attr_bold = 1

pub const attr_italic = 2

pub const attr_underline = 4

pub const attr_strikethrough = 8

/// A named style definition for batch registration.
pub type StyleDef {
  StyleDef(
    name: String,
    fg: #(Float, Float, Float, Float),
    bg: #(Float, Float, Float, Float),
    attributes: Int,
  )
}

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

/// Register a style with foreground color only (transparent background, no attributes).
pub fn register_fg(
  style: ffi.SyntaxStyle,
  name: String,
  fg: #(Float, Float, Float, Float),
) -> Int {
  register(style, name, fg, #(0.0, 0.0, 0.0, 0.0), attr_none)
}

/// Register multiple styles at once from a list of StyleDef records.
/// Returns the list of registered style IDs.
pub fn register_all(
  style: ffi.SyntaxStyle,
  defs: List(StyleDef),
) -> List(Int) {
  do_register_all(style, defs, [])
}

fn do_register_all(
  style: ffi.SyntaxStyle,
  defs: List(StyleDef),
  acc: List(Int),
) -> List(Int) {
  case defs {
    [] -> reverse(acc)
    [StyleDef(name:, fg:, bg:, attributes:), ..rest] -> {
      let id = register(style, name, fg, bg, attributes)
      do_register_all(style, rest, [id, ..acc])
    }
  }
}

fn reverse(items: List(a)) -> List(a) {
  do_reverse(items, [])
}

fn do_reverse(items: List(a), acc: List(a)) -> List(a) {
  case items {
    [] -> acc
    [first, ..rest] -> do_reverse(rest, [first, ..acc])
  }
}
