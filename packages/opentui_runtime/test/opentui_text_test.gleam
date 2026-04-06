import gleeunit/should
import opentui/text

pub fn truncate_end_adds_ellipsis_test() {
  text.truncate_end("abcdefghij", 6)
  |> should.equal("abcde…")
}

pub fn truncate_end_no_op_when_fits_test() {
  text.truncate_end("abc", 5)
  |> should.equal("abc")
}

pub fn truncate_end_width_one_gives_ellipsis_test() {
  text.truncate_end("abcdef", 1)
  |> should.equal("…")
}

pub fn truncate_end_width_zero_gives_empty_test() {
  text.truncate_end("abcdef", 0)
  |> should.equal("")
}

pub fn truncate_middle_keeps_ends_test() {
  text.truncate_middle("abcdefghij", 7)
  |> should.equal("abc…hij")
}

pub fn truncate_middle_width_one_gives_ellipsis_test() {
  text.truncate_middle("abcdef", 1)
  |> should.equal("…")
}

pub fn truncate_middle_no_op_when_fits_test() {
  text.truncate_middle("ab", 5)
  |> should.equal("ab")
}

pub fn word_wrap_splits_words_test() {
  text.wrap("alpha beta gamma", 10, text.WordWrap)
  |> should.equal(["alpha beta", "gamma"])
}

pub fn character_wrap_splits_at_boundary_test() {
  text.wrap("abcdefghij", 4, text.CharacterWrap)
  |> should.equal(["abcd", "efgh", "ij"])
}

pub fn no_wrap_returns_single_line_test() {
  text.wrap("alpha beta gamma", 5, text.NoWrap)
  |> should.equal(["alpha beta gamma"])
}

pub fn wrap_preserves_newlines_test() {
  text.wrap("one\ntwo\nthree", 20, text.WordWrap)
  |> should.equal(["one", "two", "three"])
}

pub fn wrap_zero_width_gives_empty_test() {
  text.wrap("anything", 0, text.WordWrap)
  |> should.equal([""])
}

pub fn word_wrap_long_word_stays_intact_test() {
  text.wrap("superlongword short", 8, text.WordWrap)
  |> should.equal(["superlongword", "short"])
}

pub fn wrap_empty_string_test() {
  text.wrap("", 10, text.WordWrap)
  |> should.equal([""])
}
