import gleam/list
import opentui/buffer
import opentui/ffi

pub type Color {
  Color(Float, Float, Float, Float)
}

pub type DrawOp {
  FillRect(x: Int, y: Int, width: Int, height: Int, color: Color)
  Text(x: Int, y: Int, content: String, fg: Color, bg: Color, attrs: Int)
  Cell(x: Int, y: Int, codepoint: Int, fg: Color, bg: Color, attrs: Int)
}

pub fn fill_rect(
  x: Int,
  y: Int,
  width: Int,
  height: Int,
  color: Color,
) -> DrawOp {
  FillRect(x, y, width, height, color)
}

pub fn text(
  x: Int,
  y: Int,
  content: String,
  fg: Color,
  bg: Color,
  attrs: Int,
) -> DrawOp {
  Text(x, y, content, fg, bg, attrs)
}

pub fn cell(
  x: Int,
  y: Int,
  codepoint: Int,
  fg: Color,
  bg: Color,
  attrs: Int,
) -> DrawOp {
  Cell(x, y, codepoint, fg, bg, attrs)
}

pub fn append(plan: List(DrawOp), op: DrawOp) -> List(DrawOp) {
  list.append(plan, [op])
}

pub fn concat(plans: List(List(DrawOp))) -> List(DrawOp) {
  list.flatten(plans)
}

pub fn map(plan: List(DrawOp), f: fn(DrawOp) -> DrawOp) -> List(DrawOp) {
  list.map(plan, f)
}

pub fn render(buf: ffi.Buffer, plan: List(DrawOp)) -> Nil {
  case plan {
    [] -> Nil
    [op, ..rest] -> {
      render_op(buf, op)
      render(buf, rest)
    }
  }
}

pub fn op_count(plan: List(DrawOp)) -> Int {
  list.length(plan)
}

fn render_op(buf: ffi.Buffer, op: DrawOp) -> Nil {
  case op {
    FillRect(x, y, width, height, color) ->
      buffer.fill_rect(buf, x, y, width, height, to_tuple(color))
    Text(x, y, content, fg, bg, attrs) ->
      buffer.draw_text(buf, content, x, y, to_tuple(fg), to_tuple(bg), attrs)
    Cell(x, y, codepoint, fg, bg, attrs) ->
      buffer.set_cell(buf, x, y, codepoint, to_tuple(fg), to_tuple(bg), attrs)
  }
}

fn to_tuple(color: Color) -> #(Float, Float, Float, Float) {
  case color {
    Color(r, g, b, a) -> #(r, g, b, a)
  }
}
