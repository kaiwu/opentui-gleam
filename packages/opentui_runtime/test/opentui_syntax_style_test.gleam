import gleeunit/should
import opentui/syntax_style

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
