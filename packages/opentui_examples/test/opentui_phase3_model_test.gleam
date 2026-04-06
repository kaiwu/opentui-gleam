import gleam/list
import gleam/string
import gleeunit/should
import opentui/examples/phase3_model as model

// --- Log ---

pub fn level_label_returns_correct_strings_test() {
  let _ = model.level_label(model.Debug) |> should.equal("DEBUG")
  let _ = model.level_label(model.Info) |> should.equal("INFO")
  let _ = model.level_label(model.Warn) |> should.equal("WARN")
  model.level_label(model.ErrorLevel) |> should.equal("ERROR")
}

pub fn level_color_index_is_distinct_test() {
  let _ = model.level_color_index(model.Debug) |> should.equal(0)
  let _ = model.level_color_index(model.Info) |> should.equal(1)
  let _ = model.level_color_index(model.Warn) |> should.equal(2)
  model.level_color_index(model.ErrorLevel) |> should.equal(3)
}

pub fn append_entry_respects_max_test() {
  let e1 = model.LogEntry(model.Info, "one")
  let e2 = model.LogEntry(model.Warn, "two")
  let e3 = model.LogEntry(model.Debug, "three")

  let entries =
    []
    |> model.append_entry(e1, 2)
    |> model.append_entry(e2, 2)
    |> model.append_entry(e3, 2)

  let _ = list.length(entries) |> should.equal(2)
  case entries {
    [a, b] -> {
      let _ = a.message |> should.equal("two")
      b.message |> should.equal("three")
    }
    _ -> panic as "expected 2 entries"
  }
}

pub fn format_entry_includes_level_and_message_test() {
  let entry = model.LogEntry(model.Warn, "disk full")
  let formatted = model.format_entry(entry, 5)
  let _ = string.contains(formatted, "WARN") |> should.equal(True)
  string.contains(formatted, "disk full") |> should.equal(True)
}

// --- Selection ---

pub fn selection_range_normalizes_test() {
  let _ = model.selection_range(model.Selection(2, 5)) |> should.equal(#(2, 5))
  model.selection_range(model.Selection(5, 2)) |> should.equal(#(2, 5))
}

pub fn extend_selection_moves_focus_only_test() {
  let sel = model.Selection(3, 3)
  let extended = model.extend_selection(sel, 4)
  let _ = extended.anchor |> should.equal(3)
  extended.focus |> should.equal(7)
}

pub fn collapse_selection_sets_both_to_focus_test() {
  let sel = model.Selection(2, 8)
  let collapsed = model.collapse_selection(sel)
  let _ = collapsed.anchor |> should.equal(8)
  collapsed.focus |> should.equal(8)
}

pub fn selection_contains_checks_range_test() {
  let sel = model.Selection(3, 7)
  let _ = model.selection_contains(sel, 2) |> should.equal(False)
  let _ = model.selection_contains(sel, 3) |> should.equal(True)
  let _ = model.selection_contains(sel, 5) |> should.equal(True)
  let _ = model.selection_contains(sel, 6) |> should.equal(True)
  model.selection_contains(sel, 7) |> should.equal(False)
}

pub fn selection_contains_backward_selection_test() {
  let sel = model.Selection(7, 3)
  let _ = model.selection_contains(sel, 3) |> should.equal(True)
  model.selection_contains(sel, 7) |> should.equal(False)
}

pub fn selection_length_test() {
  let _ =
    model.selection_length(model.Selection(3, 7)) |> should.equal(4)
  model.selection_length(model.Selection(7, 3)) |> should.equal(4)
}

// --- Tokenizer ---

pub fn tokenize_identifies_keywords_test() {
  let tokens = model.tokenize("pub fn main")
  let keywords =
    tokens
    |> list.filter(fn(t) { t.style == model.Keyword })
  list.length(keywords) |> should.equal(2)
}

pub fn tokenize_identifies_strings_test() {
  let tokens = model.tokenize("let x = \"hello\"")
  let strings =
    tokens
    |> list.filter(fn(t) { t.style == model.StringLit })
  let _ = list.length(strings) |> should.equal(1)
  case strings {
    [t] -> string.contains(t.text, "hello") |> should.equal(True)
    _ -> panic as "expected one string token"
  }
}

pub fn tokenize_identifies_comments_test() {
  let tokens = model.tokenize("let x // a comment")
  let comments =
    tokens
    |> list.filter(fn(t) { t.style == model.Comment })
  list.length(comments) |> should.equal(1)
}

pub fn tokenize_identifies_numbers_test() {
  let tokens = model.tokenize("let x = 42")
  let numbers =
    tokens
    |> list.filter(fn(t) { t.style == model.Number })
  list.length(numbers) |> should.equal(1)
}

pub fn token_text_roundtrips_test() {
  let line = "pub fn main()"
  model.token_text(model.tokenize(line)) |> should.equal(line)
}

// --- Table ---

pub fn column_widths_picks_max_test() {
  let widths =
    model.column_widths(
      ["Name", "Age"],
      [["Alexander", "30"], ["Bo", "5"]],
      3,
    )
  widths |> should.equal([9, 3])
}

pub fn pad_cell_aligns_correctly_test() {
  let _ = model.pad_cell("hi", 6, model.AlignLeft) |> should.equal("hi    ")
  let _ = model.pad_cell("hi", 6, model.AlignRight) |> should.equal("    hi")
  model.pad_cell("hi", 6, model.AlignCenter) |> should.equal("  hi  ")
}

pub fn format_table_produces_correct_lines_test() {
  let lines =
    model.format_table(
      ["A", "B"],
      [["1", "2"], ["3", "4"]],
      [model.AlignLeft, model.AlignRight],
    )
  // top + header + separator + 2 rows + bottom = 6
  list.length(lines) |> should.equal(6)
}

pub fn format_table_top_uses_box_chars_test() {
  let top = model.format_table_top([5, 3])
  let _ = string.starts_with(top, "┌") |> should.equal(True)
  string.contains(top, "┬") |> should.equal(True)
}

// --- Diff ---

pub fn parse_unified_diff_classifies_lines_test() {
  let diff =
    "@@ -1,3 +1,3 @@\n context\n-old line\n+new line\n more context"
  let lines = model.parse_unified_diff(diff)
  let _ = list.length(lines) |> should.equal(5)
  case lines {
    [h, c1, r, a, c2] -> {
      let _ = h.kind |> should.equal(model.DiffHeader)
      let _ = c1.kind |> should.equal(model.Context)
      let _ = r.kind |> should.equal(model.Removed)
      let _ = a.kind |> should.equal(model.Added)
      c2.kind |> should.equal(model.Context)
    }
    _ -> panic as "expected 5 diff lines"
  }
}

pub fn diff_prefix_returns_correct_chars_test() {
  let _ = model.diff_prefix(model.Added) |> should.equal("+")
  let _ = model.diff_prefix(model.Removed) |> should.equal("-")
  model.diff_prefix(model.Context) |> should.equal(" ")
}

// --- Markdown ---

pub fn parse_markdown_heading_test() {
  let blocks = model.parse_markdown_blocks("# Title\n\nSome text.")
  case blocks {
    [model.MdHeading(1, "Title"), model.MdParagraph("Some text.")] -> Nil
    _ -> panic as "expected heading + paragraph"
  }
}

pub fn parse_markdown_code_block_test() {
  let blocks =
    model.parse_markdown_blocks("```gleam\nlet x = 1\n```")
  case blocks {
    [model.MdCodeBlock("gleam", "let x = 1")] -> Nil
    _ -> panic as "expected code block"
  }
}

pub fn parse_markdown_bullet_list_test() {
  let blocks =
    model.parse_markdown_blocks("- alpha\n- beta\n- gamma")
  case blocks {
    [model.MdBulletList(items)] ->
      items |> should.equal(["alpha", "beta", "gamma"])
    _ -> panic as "expected bullet list"
  }
}

pub fn parse_markdown_hrule_test() {
  let blocks = model.parse_markdown_blocks("---")
  case blocks {
    [model.MdHRule] -> Nil
    _ -> panic as "expected hrule"
  }
}

pub fn parse_markdown_multi_level_headings_test() {
  let blocks =
    model.parse_markdown_blocks("# H1\n## H2\n### H3")
  case blocks {
    [model.MdHeading(1, "H1"), model.MdHeading(2, "H2"), model.MdHeading(3, "H3")] ->
      Nil
    _ -> panic as "expected three headings"
  }
}

// --- Extmark ---

pub fn extmarks_at_filters_correctly_test() {
  let marks = [
    model.Extmark(5, 10, "type"),
    model.Extmark(15, 20, "inferred"),
  ]
  let _ = list.length(model.extmarks_at(marks, 7)) |> should.equal(1)
  let _ = list.length(model.extmarks_at(marks, 12)) |> should.equal(0)
  list.length(model.extmarks_at(marks, 17)) |> should.equal(1)
}

pub fn skip_extmark_jumps_forward_test() {
  let marks = [model.Extmark(5, 10, "type")]
  let _ = model.skip_extmark(marks, 6, True) |> should.equal(10)
  model.skip_extmark(marks, 3, True) |> should.equal(3)
}

pub fn skip_extmark_jumps_backward_test() {
  let marks = [model.Extmark(5, 10, "type")]
  model.skip_extmark(marks, 7, False) |> should.equal(4)
}

pub fn extmark_label_at_returns_label_test() {
  let marks = [model.Extmark(5, 10, "type")]
  let _ = model.extmark_label_at(marks, 7) |> should.equal("type")
  model.extmark_label_at(marks, 3) |> should.equal("")
}

// --- ASCII Art ---

pub fn ascii_big_returns_five_lines_test() {
  let glyph = model.ascii_big("A")
  list.length(glyph) |> should.equal(5)
}

pub fn ascii_banner_combines_characters_test() {
  let lines = model.ascii_banner("HI")
  let _ = list.length(lines) |> should.equal(5)
  // Each line should be wider than a single character (5+1+5 = 11)
  case lines {
    [first, ..] -> { string.length(first) >= 11 } |> should.equal(True)
    _ -> panic as "expected banner lines"
  }
}

pub fn ascii_big_space_is_blank_test() {
  let glyph = model.ascii_big(" ")
  case glyph {
    [a, b, c, d, e] -> {
      let _ = string.trim(a) |> should.equal("")
      let _ = string.trim(b) |> should.equal("")
      let _ = string.trim(c) |> should.equal("")
      let _ = string.trim(d) |> should.equal("")
      string.trim(e) |> should.equal("")
    }
    _ -> panic as "expected 5 lines"
  }
}

// --- Slot ---

pub fn active_slots_filters_enabled_test() {
  let slots = [
    model.Slot("header", True),
    model.Slot("sidebar", False),
    model.Slot("content", True),
  ]
  model.active_slots(slots)
  |> list.length
  |> should.equal(2)
}

pub fn toggle_slot_flips_target_test() {
  let slots = [model.Slot("a", True), model.Slot("b", False)]
  let toggled = model.toggle_slot(slots, "b")
  case toggled {
    [a, b] -> {
      let _ = a.enabled |> should.equal(True)
      b.enabled |> should.equal(True)
    }
    _ -> panic as "expected 2 slots"
  }
}

pub fn slot_names_extracts_names_test() {
  let slots = [model.Slot("x", True), model.Slot("y", False)]
  model.slot_names(slots) |> should.equal(["x", "y"])
}
