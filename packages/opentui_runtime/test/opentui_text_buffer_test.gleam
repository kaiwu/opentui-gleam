import gleeunit/should
import opentui/text_buffer
import opentui/types

pub fn create_and_append_test() {
  let buf = text_buffer.create(types.Normal)
  let _ = text_buffer.length(buf) |> should.equal(0)

  text_buffer.append(buf, "hello")
  let _ = { text_buffer.length(buf) > 0 } |> should.equal(True)
  text_buffer.destroy(buf)
}

pub fn text_returns_appended_content_test() {
  let buf = text_buffer.create(types.Normal)
  text_buffer.append(buf, "gleam")
  let _ = text_buffer.text(buf) |> should.equal("gleam")
  text_buffer.destroy(buf)
}

pub fn clear_empties_buffer_test() {
  let buf = text_buffer.create(types.Normal)
  text_buffer.append(buf, "abc")
  text_buffer.clear(buf)
  let _ = text_buffer.length(buf) |> should.equal(0)
  let _ = text_buffer.text(buf) |> should.equal("")
  text_buffer.destroy(buf)
}

pub fn multiple_appends_concatenate_test() {
  let buf = text_buffer.create(types.Normal)
  text_buffer.append(buf, "one")
  text_buffer.append(buf, "two")
  let content = text_buffer.text(buf)
  let _ = content |> should.equal("onetwo")
  text_buffer.destroy(buf)
}
