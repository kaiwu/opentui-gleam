// test/opentui_test.gleam
import gleeunit
import gleeunit/should

pub fn main() {
  gleeunit.main()
}

pub fn placeholder_test() {
  1
  |> should.equal(1)
}
