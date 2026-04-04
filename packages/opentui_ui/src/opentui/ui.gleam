import gleam/int
import gleam/list
import gleam/string
import opentui/buffer
import opentui/ffi
import opentui/text

pub type Color {
  Color(Float, Float, Float, Float)
}

pub type Border {
  NoBorder
  HasBorder(title: String, fg: Color)
}

pub type BoxProps {
  BoxProps(
    x: Int,
    y: Int,
    width: Int,
    height: Int,
    padding: Int,
    background: Color,
    border: Border,
  )
}

pub type ColumnProps {
  ColumnProps(gap: Int)
}

pub type TextProps {
  TextProps(fg: Color, bg: Color, attributes: Int)
}

pub type ParagraphProps {
  ParagraphProps(
    fg: Color,
    bg: Color,
    attributes: Int,
    wrap: text.WrapMode,
    max_lines: Int,
  )
}

pub type Element {
  Box(BoxProps, List(Element))
  Column(ColumnProps, List(Element))
  Text(TextProps, String)
  Paragraph(ParagraphProps, String)
  Spacer(Int)
}

type Rect {
  Rect(x: Int, y: Int, width: Int, height: Int)
}

pub fn render_all(buf: ffi.Buffer, elements: List(Element)) -> Nil {
  render_absolute(buf, elements)
}

pub fn fold(
  elements: List(Element),
  initial: a,
  visit: fn(a, Element) -> a,
) -> a {
  list.fold(elements, initial, fn(acc, element) {
    fold_element(element, acc, visit)
  })
}

pub fn to_string(elements: List(Element)) -> String {
  elements
  |> list.map(element_to_string)
  |> string.join(with: "\n")
}

fn render_absolute(buf: ffi.Buffer, elements: List(Element)) -> Nil {
  case elements {
    [] -> Nil
    [element, ..rest] -> {
      let _ = render_element(buf, Rect(0, 0, 0, 0), element)
      render_absolute(buf, rest)
    }
  }
}

fn render_element(buf: ffi.Buffer, rect: Rect, element: Element) -> Int {
  case element {
    Box(props, children) -> render_box(buf, props, children)
    Column(props, children) -> render_column(buf, rect, props, children)
    Text(props, content) -> render_text(buf, rect, props, content)
    Paragraph(props, content) -> render_paragraph(buf, rect, props, content)
    Spacer(height) -> height
  }
}

fn render_box(buf: ffi.Buffer, props: BoxProps, children: List(Element)) -> Int {
  let BoxProps(x:, y:, width:, height:, padding:, background:, border:) = props
  buffer.fill_rect(buf, x, y, width, height, color_to_tuple(background))

  case border {
    NoBorder -> Nil
    HasBorder(title:, fg:) ->
      draw_border(buf, x, y, width, height, title, fg, background)
  }

  let border_offset = case border {
    NoBorder -> 0
    HasBorder(_, _) -> 1
  }
  let inner_width = width - border_offset * 2 - padding * 2
  let inner_height = height - border_offset * 2 - padding * 2
  let inner_rect =
    Rect(
      x + border_offset + padding,
      y + border_offset + padding,
      inner_width,
      inner_height,
    )

  let _ = render_children_in_rect(buf, inner_rect, children)
  height
}

fn render_children_in_rect(
  buf: ffi.Buffer,
  rect: Rect,
  children: List(Element),
) -> Int {
  case rect.width <= 0 || rect.height <= 0 {
    True -> 0
    False ->
      case children {
        [] -> 0
        [element, ..rest] -> {
          let used = render_element(buf, rect, element)
          let next_rect =
            Rect(rect.x, rect.y + used, rect.width, rect.height - used)
          used + render_children_in_rect(buf, next_rect, rest)
        }
      }
  }
}

fn render_column(
  buf: ffi.Buffer,
  rect: Rect,
  props: ColumnProps,
  children: List(Element),
) -> Int {
  let ColumnProps(gap:) = props
  render_column_items(buf, rect, gap, children, 0)
}

fn render_column_items(
  buf: ffi.Buffer,
  rect: Rect,
  gap: Int,
  children: List(Element),
  used: Int,
) -> Int {
  case rect.width <= 0 || rect.height - used <= 0 {
    True -> used
    False ->
      case children {
        [] -> used
        [element] -> {
          let child_rect =
            Rect(rect.x, rect.y + used, rect.width, rect.height - used)
          used + render_element(buf, child_rect, element)
        }
        [element, ..rest] -> {
          let child_rect =
            Rect(rect.x, rect.y + used, rect.width, rect.height - used)
          let child_used = render_element(buf, child_rect, element)
          render_column_items(buf, rect, gap, rest, used + child_used + gap)
        }
      }
  }
}

fn render_text(
  buf: ffi.Buffer,
  rect: Rect,
  props: TextProps,
  content: String,
) -> Int {
  case rect.width <= 0 || rect.height <= 0 {
    True -> 0
    False -> {
      let TextProps(fg:, bg:, attributes:) = props
      buffer.draw_text(
        buf,
        text.truncate_end(content, rect.width),
        rect.x,
        rect.y,
        color_to_tuple(fg),
        color_to_tuple(bg),
        attributes,
      )
      1
    }
  }
}

fn render_paragraph(
  buf: ffi.Buffer,
  rect: Rect,
  props: ParagraphProps,
  content: String,
) -> Int {
  case rect.width <= 0 || rect.height <= 0 {
    True -> 0
    False -> {
      let ParagraphProps(fg:, bg:, attributes:, wrap:, max_lines:) = props
      let wrapped = text.wrap(content, rect.width, wrap)
      let lines = take_lines(wrapped, limit_lines(rect.height, max_lines))

      lines
      |> list.index_map(fn(line, i) {
        buffer.draw_text(
          buf,
          text.truncate_end(line, rect.width),
          rect.x,
          rect.y + i,
          color_to_tuple(fg),
          color_to_tuple(bg),
          attributes,
        )
      })
      |> fn(_) { Nil }()

      list.length(lines)
    }
  }
}

fn limit_lines(height: Int, max_lines: Int) -> Int {
  case max_lines <= 0 || max_lines > height {
    True -> height
    False -> max_lines
  }
}

fn take_lines(lines: List(String), limit: Int) -> List(String) {
  case limit <= 0, lines {
    True, _ -> []
    False, [] -> []
    False, [line, ..rest] -> [line, ..take_lines(rest, limit - 1)]
  }
}

fn draw_border(
  buf: ffi.Buffer,
  x: Int,
  y: Int,
  width: Int,
  height: Int,
  title: String,
  fg: Color,
  background: Color,
) -> Nil {
  each_index(width, fn(i) {
    buffer.set_cell(
      buf,
      x + i,
      y,
      0x2500,
      color_to_tuple(fg),
      color_to_tuple(background),
      0,
    )
    buffer.set_cell(
      buf,
      x + i,
      y + height - 1,
      0x2500,
      color_to_tuple(fg),
      color_to_tuple(background),
      0,
    )
  })

  each_index(height, fn(i) {
    buffer.set_cell(
      buf,
      x,
      y + i,
      0x2502,
      color_to_tuple(fg),
      color_to_tuple(background),
      0,
    )
    buffer.set_cell(
      buf,
      x + width - 1,
      y + i,
      0x2502,
      color_to_tuple(fg),
      color_to_tuple(background),
      0,
    )
  })

  buffer.set_cell(
    buf,
    x,
    y,
    0x250c,
    color_to_tuple(fg),
    color_to_tuple(background),
    0,
  )
  buffer.set_cell(
    buf,
    x + width - 1,
    y,
    0x2510,
    color_to_tuple(fg),
    color_to_tuple(background),
    0,
  )
  buffer.set_cell(
    buf,
    x,
    y + height - 1,
    0x2514,
    color_to_tuple(fg),
    color_to_tuple(background),
    0,
  )
  buffer.set_cell(
    buf,
    x + width - 1,
    y + height - 1,
    0x2518,
    color_to_tuple(fg),
    color_to_tuple(background),
    0,
  )

  case title {
    "" -> Nil
    _ ->
      buffer.draw_text(
        buf,
        " " <> title <> " ",
        x + 2,
        y,
        color_to_tuple(fg),
        color_to_tuple(background),
        1,
      )
  }
}

fn color_to_tuple(color: Color) -> #(Float, Float, Float, Float) {
  case color {
    Color(r, g, b, a) -> #(r, g, b, a)
  }
}

fn each_index(n: Int, f: fn(Int) -> Nil) -> Nil {
  case n <= 0 {
    True -> Nil
    False -> each_index_loop(0, n, f)
  }
}

fn each_index_loop(i: Int, n: Int, f: fn(Int) -> Nil) -> Nil {
  case i >= n {
    True -> Nil
    False -> {
      f(i)
      each_index_loop(i + 1, n, f)
    }
  }
}

fn fold_element(element: Element, acc: a, visit: fn(a, Element) -> a) -> a {
  let next = visit(acc, element)
  case element {
    Box(_, children) ->
      list.fold(children, next, fn(inner, child) {
        fold_element(child, inner, visit)
      })
    Column(_, children) ->
      list.fold(children, next, fn(inner, child) {
        fold_element(child, inner, visit)
      })
    Text(_, _) | Paragraph(_, _) | Spacer(_) -> next
  }
}

fn element_to_string(element: Element) -> String {
  case element {
    Box(_, children) -> "Box([" <> children_to_string(children) <> "])"
    Column(_, children) -> "Column([" <> children_to_string(children) <> "])"
    Text(_, content) -> "Text(\"" <> content <> "\")"
    Paragraph(_, content) ->
      "Paragraph(\"" <> text.truncate_end(content, 24) <> "\")"
    Spacer(height) -> "Spacer(" <> int.to_string(height) <> ")"
  }
}

fn children_to_string(children: List(Element)) -> String {
  children
  |> list.map(element_to_string)
  |> string.join(with: ", ")
}
