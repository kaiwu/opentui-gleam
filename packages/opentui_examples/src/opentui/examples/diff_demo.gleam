import gleam/int
import gleam/list
import opentui/buffer
import opentui/examples/common
import opentui/examples/phase2_model
import opentui/examples/phase2_state as state
import opentui/examples/phase3_model as model
import opentui/ffi

pub fn main() -> Nil {
  let scroll = state.create_int(0)

  common.run_interactive_demo(
    "Diff Demo",
    "Diff Demo",
    fn(key) {
      let k = phase2_model.parse_key(key)
      let diff_lines = model.parse_unified_diff(sample_diff())
      state.set_int(
        scroll,
        phase2_model.adjust_scroll(
          state.get_int(scroll),
          k,
          phase2_model.max_scroll_offset(list.length(diff_lines), 14),
        ),
      )
    },
    fn(buf) { draw_body(buf, scroll) },
  )
}

fn draw_body(buf: ffi.Buffer, scroll: state.IntCell) -> Nil {
  let offset = state.get_int(scroll)
  let all_lines = model.parse_unified_diff(sample_diff())
  let visible = visible_diff_lines(all_lines, offset, 14)

  common.draw_panel(buf, 2, 3, 56, 18, "Unified Diff")
  draw_diff_lines(buf, visible, 0)

  common.draw_panel(buf, 60, 3, 18, 18, "Info")
  buffer.draw_text(buf, "Lines: " <> int.to_string(list.length(all_lines)), 62, 5, common.fg_color, common.panel_bg, 0)
  buffer.draw_text(buf, "Offset: " <> int.to_string(offset), 62, 6, common.fg_color, common.panel_bg, 0)
  buffer.draw_text(buf, "Up/Down", 62, 8, common.muted_fg, common.panel_bg, 0)
  buffer.draw_text(buf, "to scroll", 62, 9, common.muted_fg, common.panel_bg, 0)
  buffer.draw_text(buf, "Parsed from", 62, 11, common.muted_fg, common.panel_bg, 0)
  buffer.draw_text(buf, "unified diff", 62, 12, common.muted_fg, common.panel_bg, 0)
  buffer.draw_text(buf, "via pure FP", 62, 13, common.muted_fg, common.panel_bg, 0)
  buffer.draw_text(buf, "classifier.", 62, 14, common.muted_fg, common.panel_bg, 0)
}

fn draw_diff_lines(buf: ffi.Buffer, lines: List(model.DiffLine), row: Int) -> Nil {
  case lines {
    [] -> Nil
    [line, ..rest] -> {
      let color = diff_color(line.kind)
      let prefix = model.diff_prefix(line.kind)
      let gutter = int.to_string(line.line_no)
      let pad = case line.line_no < 10 {
        True -> "  "
        False -> " "
      }
      buffer.draw_text(buf, pad <> gutter, 4, 5 + row, common.muted_fg, common.panel_bg, 0)
      buffer.draw_text(buf, prefix, 8, 5 + row, color, common.panel_bg, 1)
      buffer.draw_text(buf, line.content, 10, 5 + row, color, common.panel_bg, 0)
      draw_diff_lines(buf, rest, row + 1)
    }
  }
}

fn diff_color(kind: model.DiffKind) -> #(Float, Float, Float, Float) {
  case kind {
    model.Added -> common.accent_green
    model.Removed -> common.accent_pink
    model.DiffHeader -> common.accent_yellow
    model.Context -> common.fg_color
  }
}

fn visible_diff_lines(
  lines: List(model.DiffLine),
  offset: Int,
  count: Int,
) -> List(model.DiffLine) {
  lines
  |> list.drop(offset)
  |> list.take(count)
}

fn sample_diff() -> String {
  "@@ -1,8 +1,9 @@
 import gleam/list
 import gleam/string
+import gleam/int

 pub type Element {
-  Box(List(Style), List(Element))
+  Box(styles: List(Style), children: List(Element))
   Text(List(Style), String)
+  Paragraph(List(Style), String)
   Spacer(Int)
 }

-pub fn render(el: Element) {
+pub fn render_all(elements: List(Element)) {
+  list.each(elements, render_element)
 }"
}
