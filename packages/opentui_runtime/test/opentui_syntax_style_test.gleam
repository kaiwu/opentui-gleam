import gleeunit/should
import opentui/syntax_style.{StyleDef}

pub fn create_and_register_test() {
  let style = syntax_style.create()
  let id =
    syntax_style.register(
      style,
      "keyword",
      #(0.8, 0.2, 0.4, 1.0),
      #(0.0, 0.0, 0.0, 1.0),
      1,
    )
  let _ = { id >= 0 } |> should.equal(True)
  syntax_style.destroy(style)
}

pub fn multiple_registrations_produce_distinct_ids_test() {
  let style = syntax_style.create()
  let id_a =
    syntax_style.register(
      style,
      "keyword",
      #(0.8, 0.2, 0.4, 1.0),
      #(0.0, 0.0, 0.0, 1.0),
      1,
    )
  let id_b =
    syntax_style.register(
      style,
      "string",
      #(0.3, 0.7, 0.3, 1.0),
      #(0.0, 0.0, 0.0, 1.0),
      0,
    )
  let _ = { id_a != id_b } |> should.equal(True)
  syntax_style.destroy(style)
}

pub fn register_fg_test() {
  let style = syntax_style.create()
  let id = syntax_style.register_fg(style, "comment", #(0.5, 0.5, 0.5, 1.0))
  let _ = { id >= 0 } |> should.equal(True)
  syntax_style.destroy(style)
}

pub fn register_all_test() {
  let style = syntax_style.create()
  let ids =
    syntax_style.register_all(style, [
      StyleDef("keyword", #(0.8, 0.2, 0.4, 1.0), #(0.0, 0.0, 0.0, 1.0), syntax_style.attr_bold),
      StyleDef("string", #(0.3, 0.7, 0.3, 1.0), #(0.0, 0.0, 0.0, 1.0), syntax_style.attr_none),
      StyleDef("comment", #(0.5, 0.5, 0.5, 1.0), #(0.0, 0.0, 0.0, 0.0), syntax_style.attr_italic),
    ])
  case ids {
    [a, b, c] -> {
      let _ = { a != b } |> should.equal(True)
      let _ = { b != c } |> should.equal(True)
      Nil
    }
    _ -> should.fail()
  }
  syntax_style.destroy(style)
}

pub fn attr_flags_are_distinct_test() {
  let _ = { syntax_style.attr_bold != syntax_style.attr_italic } |> should.equal(True)
  let _ = { syntax_style.attr_underline != syntax_style.attr_strikethrough } |> should.equal(True)
}
