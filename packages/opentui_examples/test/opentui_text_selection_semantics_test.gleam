import gleeunit/should
import opentui/examples/phase3_model as model
import opentui/examples/text_selection_semantics as semantics

pub fn no_selection_report_test() {
  let report =
    semantics.build_report(sample_leaves(), False, model.Selection(0, 0))
  let _ = report.state |> should.equal(semantics.NoSelection)
  let _ = report.selected_chars |> should.equal(0)
  let _ = report.selected_renderables |> should.equal(0)
  report.primary_container_label |> should.equal("none")
}

pub fn empty_selection_keeps_container_context_test() {
  let report =
    semantics.build_report(sample_leaves(), True, model.Selection(2, 2))
  let _ = report.state |> should.equal(semantics.EmptySelection)
  let _ = report.selected_chars |> should.equal(0)
  report.primary_container_label |> should.equal("Document Section 1")
}

pub fn active_selection_tracks_renderables_and_containers_test() {
  let report =
    semantics.build_report(sample_leaves(), True, model.Selection(0, 20))
  let _ = report.state |> should.equal(semantics.ActiveSelection)
  let _ = report.selected_renderables |> should.equal(2)
  let _ = report.total_renderables |> should.equal(5)
  let _ = report.selected_containers |> should.equal(1)
  report.primary_container_label |> should.equal("Document Section 1")
}

pub fn cross_container_selection_reports_multiple_containers_test() {
  let report =
    semantics.build_report(sample_leaves(), True, model.Selection(0, 80))
  let _ = report.state |> should.equal(semantics.ActiveSelection)
  let _ = report.selected_containers |> should.equal(4)
  let _ = report.line_count |> should.equal(5)
  let _ = report.excerpt_middle |> should.equal("...")
  report.primary_container_label |> should.equal("multiple containers")
}

fn sample_leaves() -> List(semantics.TextLeaf) {
  [
    semantics.TextLeaf(
      "left",
      "Document Section 1",
      "text1",
      "Paragraph 1",
      "alpha beta",
    ),
    semantics.TextLeaf(
      "left",
      "Document Section 1",
      "text2",
      "Paragraph 2",
      "gamma delta",
    ),
    semantics.TextLeaf(
      "nested",
      "Nested Box",
      "nested1",
      "Important label",
      "important",
    ),
    semantics.TextLeaf(
      "code",
      "Code Example",
      "code1",
      "Code line 1",
      "function pick()",
    ),
    semantics.TextLeaf(
      "readme",
      "README",
      "readme1",
      "Readme line",
      "Selection Demo",
    ),
  ]
}
