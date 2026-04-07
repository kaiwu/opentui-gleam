import gleam/list
import gleeunit/should
import opentui/grapheme
import opentui/types

pub fn encode_ascii_test() {
  let chars = grapheme.encode("Hi", types.Normal)
  let _ = list.length(chars) |> should.equal(2)
  case chars {
    [first, second] -> {
      let _ = first.codepoint |> should.equal(72)
      let _ = first.width |> should.equal(1)
      let _ = second.codepoint |> should.equal(105)
      second.width |> should.equal(1)
    }
    _ -> panic as "expected 2 chars"
  }
}

pub fn display_width_ascii_test() {
  grapheme.display_width("hello", types.Normal)
  |> should.equal(5)
}

pub fn encode_empty_test() {
  let chars = grapheme.encode("", types.Normal)
  list.length(chars) |> should.equal(0)
}

pub fn display_width_empty_test() {
  grapheme.display_width("", types.Normal)
  |> should.equal(0)
}
