import gleeunit/should
import opentui/text

pub fn truncate_end_adds_ellipsis_test() {
  text.truncate_end("abcdefghij", 6)
  |> should.equal("abcde…")
}

pub fn truncate_middle_keeps_ends_test() {
  text.truncate_middle("abcdefghij", 7)
  |> should.equal("abc…hij")
}

pub fn word_wrap_splits_words_test() {
  text.wrap("alpha beta gamma", 10, text.WordWrap)
  |> should.equal(["alpha beta", "gamma"])
}
