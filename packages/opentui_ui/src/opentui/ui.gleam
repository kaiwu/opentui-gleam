import gleam/int
import gleam/list
import gleam/string
import opentui/buffer
import opentui/ffi
import opentui/text

pub type Color {
  Color(Float, Float, Float, Float)
}

pub type Truncation {
  NoTruncation
  EndTruncate
  MiddleTruncate
}

pub type Style {
  X(Int)
  Y(Int)
  Width(Int)
  Height(Int)
  Padding(Int)
  Gap(Int)
  Background(Color)
  Foreground(Color)
  Border(String, Color)
  Attributes(Int)
  Wrap(text.WrapMode)
  MaxLines(Int)
  Truncate(Truncation)
}

pub type Element {
  Box(List(Style), List(Element))
  Column(List(Style), List(Element))
  Row(List(Style), List(Element))
  Text(List(Style), String)
  Paragraph(List(Style), String)
  Spacer(Int)
}

type Rect {
  Rect(x: Int, y: Int, width: Int, height: Int)
}

pub type LayoutNode {
  LayoutNode(
    kind: String,
    x: Int,
    y: Int,
    width: Int,
    height: Int,
    children: List(LayoutNode),
  )
}

type BorderStyle {
  NoBorder
  HasBorder(title: String, fg: Color)
}

pub fn render_all(buf: ffi.Buffer, elements: List(Element)) -> Nil {
  render_in_bounds(buf, 80, 24, elements)
}

pub fn render_in_bounds(
  buf: ffi.Buffer,
  width: Int,
  height: Int,
  elements: List(Element),
) -> Nil {
  render_absolute(buf, Rect(0, 0, width, height), elements)
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

pub fn plan(
  elements: List(Element),
  width: Int,
  height: Int,
) -> List(LayoutNode) {
  plan_absolute(elements, Rect(0, 0, width, height))
}

fn render_absolute(buf: ffi.Buffer, rect: Rect, elements: List(Element)) -> Nil {
  case elements {
    [] -> Nil
    [element, ..rest] -> {
      let _ = render_element(buf, rect, element)
      render_absolute(buf, rect, rest)
    }
  }
}

fn plan_absolute(elements: List(Element), rect: Rect) -> List(LayoutNode) {
  case elements {
    [] -> []
    [element, ..rest] -> [
      plan_element(rect, element),
      ..plan_absolute(rest, rect)
    ]
  }
}

fn plan_children_in_rect(
  children: List(Element),
  rect: Rect,
) -> List(LayoutNode) {
  case rect.width <= 0 || rect.height <= 0, children {
    True, _ -> []
    False, [] -> []
    False, [element, ..rest] -> {
      let node = plan_element(rect, element)
      let next_rect =
        Rect(
          rect.x,
          rect.y + node.height,
          rect.width,
          rect.height - node.height,
        )
      [node, ..plan_children_in_rect(rest, next_rect)]
    }
  }
}

fn plan_column_children(
  children: List(Element),
  rect: Rect,
  gap: Int,
  used: Int,
) -> List(LayoutNode) {
  case rect.width <= 0 || rect.height - used <= 0, children {
    True, _ -> []
    False, [] -> []
    False, [element] -> {
      let child_rect =
        Rect(rect.x, rect.y + used, rect.width, rect.height - used)
      [plan_element(child_rect, element)]
    }
    False, [element, ..rest] -> {
      let child_rect =
        Rect(rect.x, rect.y + used, rect.width, rect.height - used)
      let node = plan_element(child_rect, element)
      [node, ..plan_column_children(rest, rect, gap, used + node.height + gap)]
    }
  }
}

fn paragraph_used_height(
  rect: Rect,
  styles: List(Style),
  content: String,
) -> Int {
  case rect.width <= 0 || rect.height <= 0 {
    True -> 0
    False -> {
      let wrapped = text.wrap(content, rect.width, wrap_mode(styles))
      let lines =
        take_lines(wrapped, limit_lines(rect.height, max_lines(styles)))
      list.length(lines)
    }
  }
}

fn render_element(buf: ffi.Buffer, parent: Rect, element: Element) -> Int {
  case element {
    Box(styles, children) -> render_box(buf, parent, styles, children)
    Column(styles, children) -> render_column(buf, parent, styles, children)
    Row(styles, children) -> render_row(buf, parent, styles, children)
    Text(styles, content) -> render_text(buf, parent, styles, content)
    Paragraph(styles, content) -> render_paragraph(buf, parent, styles, content)
    Spacer(height) -> height
  }
}

fn plan_element(parent: Rect, element: Element) -> LayoutNode {
  case element {
    Box(styles, children) -> {
      let rect = resolve_rect(parent, styles)
      let inner_rect = box_inner_rect(rect, styles)
      LayoutNode(
        "Box",
        rect.x,
        rect.y,
        rect.width,
        rect.height,
        plan_children_in_rect(children, inner_rect),
      )
    }
    Column(styles, children) -> {
      let rect = resolve_rect(parent, styles)
      LayoutNode(
        "Column",
        rect.x,
        rect.y,
        rect.width,
        rect.height,
        plan_column_children(children, rect, gap(styles), 0),
      )
    }
    Row(styles, children) -> {
      let rect = resolve_rect(parent, styles)
      LayoutNode(
        "Row",
        rect.x,
        rect.y,
        rect.width,
        rect.height,
        plan_row_children(children, rect, gap(styles), 0),
      )
    }
    Text(styles, _content) -> {
      let rect = resolve_rect(parent, styles)
      let used_height = case rect.width <= 0 || rect.height <= 0 {
        True -> 0
        False -> 1
      }
      LayoutNode("Text", rect.x, rect.y, rect.width, used_height, [])
    }
    Paragraph(styles, content) -> {
      let rect = resolve_rect(parent, styles)
      LayoutNode(
        "Paragraph",
        rect.x,
        rect.y,
        rect.width,
        paragraph_used_height(rect, styles, content),
        [],
      )
    }
    Spacer(height) ->
      LayoutNode("Spacer", parent.x, parent.y, parent.width, height, [])
  }
}

fn render_box(
  buf: ffi.Buffer,
  parent: Rect,
  styles: List(Style),
  children: List(Element),
) -> Int {
  let rect = resolve_rect(parent, styles)
  case rect.width <= 0 || rect.height <= 0 {
    True -> 0
    False -> {
      let background = background(styles)
      buffer.fill_rect(
        buf,
        rect.x,
        rect.y,
        rect.width,
        rect.height,
        color_to_tuple(background),
      )

      let border = border_style(styles)
      case border {
        NoBorder -> Nil
        HasBorder(title:, fg:) -> draw_border(buf, rect, title, fg, background)
      }

      let border_offset = case border {
        NoBorder -> 0
        HasBorder(_, _) -> 1
      }
      let padding = padding(styles)
      let inner_rect =
        Rect(
          rect.x + border_offset + padding,
          rect.y + border_offset + padding,
          rect.width - border_offset * 2 - padding * 2,
          rect.height - border_offset * 2 - padding * 2,
        )

      let _ = render_children_in_rect(buf, inner_rect, children)
      rect.height
    }
  }
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
  parent: Rect,
  styles: List(Style),
  children: List(Element),
) -> Int {
  let rect = resolve_rect(parent, styles)
  let gap = gap(styles)
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

fn render_row(
  buf: ffi.Buffer,
  parent: Rect,
  styles: List(Style),
  children: List(Element),
) -> Int {
  let rect = resolve_rect(parent, styles)
  let g = gap(styles)
  let max_h = render_row_items(buf, rect, g, children, 0, 0)
  case max_h > 0 {
    True -> max_h
    False -> rect.height
  }
}

fn render_row_items(
  buf: ffi.Buffer,
  rect: Rect,
  gap: Int,
  children: List(Element),
  used_x: Int,
  max_height: Int,
) -> Int {
  case rect.width - used_x <= 0 {
    True -> max_height
    False ->
      case children {
        [] -> max_height
        [element] -> {
          let child_rect =
            Rect(rect.x + used_x, rect.y, rect.width - used_x, rect.height)
          let child_h = render_element(buf, child_rect, element)
          int.max(max_height, child_h)
        }
        [element, ..rest] -> {
          let child_rect =
            Rect(rect.x + used_x, rect.y, rect.width - used_x, rect.height)
          let child_w = element_width(element, child_rect)
          let child_h = render_element(buf, child_rect, element)
          render_row_items(
            buf,
            rect,
            gap,
            rest,
            used_x + child_w + gap,
            int.max(max_height, child_h),
          )
        }
      }
  }
}

fn plan_row_children(
  children: List(Element),
  rect: Rect,
  gap: Int,
  used_x: Int,
) -> List(LayoutNode) {
  case rect.width - used_x <= 0, children {
    True, _ -> []
    False, [] -> []
    False, [element] -> {
      let child_rect =
        Rect(rect.x + used_x, rect.y, rect.width - used_x, rect.height)
      [plan_element(child_rect, element)]
    }
    False, [element, ..rest] -> {
      let child_rect =
        Rect(rect.x + used_x, rect.y, rect.width - used_x, rect.height)
      let node = plan_element(child_rect, element)
      [node, ..plan_row_children(rest, rect, gap, used_x + node.width + gap)]
    }
  }
}

fn element_width(element: Element, parent: Rect) -> Int {
  case element {
    Box(styles, _) | Column(styles, _) | Row(styles, _) -> {
      int_style(
        styles,
        fn(style) {
          case style {
            Width(value) -> Ok(value)
            _ -> Error(Nil)
          }
        },
        parent.width,
      )
    }
    Text(styles, _) | Paragraph(styles, _) -> {
      int_style(
        styles,
        fn(style) {
          case style {
            Width(value) -> Ok(value)
            _ -> Error(Nil)
          }
        },
        parent.width,
      )
    }
    Spacer(_) -> 0
  }
}

fn render_text(
  buf: ffi.Buffer,
  parent: Rect,
  styles: List(Style),
  content: String,
) -> Int {
  let rect = resolve_rect(parent, styles)
  case rect.width <= 0 || rect.height <= 0 {
    True -> 0
    False -> {
      let display = truncate_content(content, rect.width, truncation(styles))
      buffer.draw_text(
        buf,
        display,
        rect.x,
        rect.y,
        color_to_tuple(foreground(styles)),
        color_to_tuple(background(styles)),
        attributes(styles),
      )
      1
    }
  }
}

fn render_paragraph(
  buf: ffi.Buffer,
  parent: Rect,
  styles: List(Style),
  content: String,
) -> Int {
  let rect = resolve_rect(parent, styles)
  case rect.width <= 0 || rect.height <= 0 {
    True -> 0
    False -> {
      let wrapped = text.wrap(content, rect.width, wrap_mode(styles))
      let lines =
        take_lines(wrapped, limit_lines(rect.height, max_lines(styles)))

      lines
      |> list.index_map(fn(line, i) {
        buffer.draw_text(
          buf,
          truncate_content(line, rect.width, truncation(styles)),
          rect.x,
          rect.y + i,
          color_to_tuple(foreground(styles)),
          color_to_tuple(background(styles)),
          attributes(styles),
        )
      })
      |> fn(_) { Nil }()

      list.length(lines)
    }
  }
}

fn resolve_rect(parent: Rect, styles: List(Style)) -> Rect {
  let x_offset =
    int_style(
      styles,
      fn(style) {
        case style {
          X(value) -> Ok(value)
          _ -> Error(Nil)
        }
      },
      0,
    )
  let y_offset =
    int_style(
      styles,
      fn(style) {
        case style {
          Y(value) -> Ok(value)
          _ -> Error(Nil)
        }
      },
      0,
    )
  let width =
    int_style(
      styles,
      fn(style) {
        case style {
          Width(value) -> Ok(value)
          _ -> Error(Nil)
        }
      },
      parent.width - x_offset,
    )
  let height =
    int_style(
      styles,
      fn(style) {
        case style {
          Height(value) -> Ok(value)
          _ -> Error(Nil)
        }
      },
      parent.height - y_offset,
    )

  Rect(parent.x + x_offset, parent.y + y_offset, width, height)
}

fn int_style(
  styles: List(Style),
  matcher: fn(Style) -> Result(Int, Nil),
  default: Int,
) -> Int {
  case styles {
    [] -> default
    [style, ..rest] ->
      case matcher(style) {
        Ok(value) -> value
        Error(_) -> int_style(rest, matcher, default)
      }
  }
}

fn color_style(
  styles: List(Style),
  matcher: fn(Style) -> Result(Color, Nil),
  default: Color,
) -> Color {
  case styles {
    [] -> default
    [style, ..rest] ->
      case matcher(style) {
        Ok(value) -> value
        Error(_) -> color_style(rest, matcher, default)
      }
  }
}

fn border_style(styles: List(Style)) -> BorderStyle {
  case styles {
    [] -> NoBorder
    [style, ..rest] ->
      case style {
        Border(title, fg) -> HasBorder(title, fg)
        _ -> border_style(rest)
      }
  }
}

fn wrap_mode(styles: List(Style)) -> text.WrapMode {
  case styles {
    [] -> text.WordWrap
    [style, ..rest] ->
      case style {
        Wrap(mode) -> mode
        _ -> wrap_mode(rest)
      }
  }
}

fn truncation(styles: List(Style)) -> Truncation {
  case styles {
    [] -> NoTruncation
    [style, ..rest] ->
      case style {
        Truncate(mode) -> mode
        _ -> truncation(rest)
      }
  }
}

fn box_inner_rect(rect: Rect, styles: List(Style)) -> Rect {
  let border_offset = case border_style(styles) {
    NoBorder -> 0
    HasBorder(_, _) -> 1
  }
  let pad = padding(styles)
  Rect(
    rect.x + border_offset + pad,
    rect.y + border_offset + pad,
    rect.width - border_offset * 2 - pad * 2,
    rect.height - border_offset * 2 - pad * 2,
  )
}

fn max_lines(styles: List(Style)) -> Int {
  int_style(
    styles,
    fn(style) {
      case style {
        MaxLines(value) -> Ok(value)
        _ -> Error(Nil)
      }
    },
    0,
  )
}

fn gap(styles: List(Style)) -> Int {
  int_style(
    styles,
    fn(style) {
      case style {
        Gap(value) -> Ok(value)
        _ -> Error(Nil)
      }
    },
    0,
  )
}

fn padding(styles: List(Style)) -> Int {
  int_style(
    styles,
    fn(style) {
      case style {
        Padding(value) -> Ok(value)
        _ -> Error(Nil)
      }
    },
    0,
  )
}

fn foreground(styles: List(Style)) -> Color {
  color_style(
    styles,
    fn(style) {
      case style {
        Foreground(value) -> Ok(value)
        _ -> Error(Nil)
      }
    },
    Color(1.0, 1.0, 1.0, 1.0),
  )
}

fn background(styles: List(Style)) -> Color {
  color_style(
    styles,
    fn(style) {
      case style {
        Background(value) -> Ok(value)
        _ -> Error(Nil)
      }
    },
    Color(0.0, 0.0, 0.0, 1.0),
  )
}

fn attributes(styles: List(Style)) -> Int {
  int_style(
    styles,
    fn(style) {
      case style {
        Attributes(value) -> Ok(value)
        _ -> Error(Nil)
      }
    },
    0,
  )
}

fn truncate_content(content: String, width: Int, mode: Truncation) -> String {
  case mode {
    NoTruncation -> text.truncate_end(content, width)
    EndTruncate -> text.truncate_end(content, width)
    MiddleTruncate -> text.truncate_middle(content, width)
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
  rect: Rect,
  title: String,
  fg: Color,
  background: Color,
) -> Nil {
  each_index(rect.width, fn(i) {
    buffer.set_cell(
      buf,
      rect.x + i,
      rect.y,
      0x2500,
      color_to_tuple(fg),
      color_to_tuple(background),
      0,
    )
    buffer.set_cell(
      buf,
      rect.x + i,
      rect.y + rect.height - 1,
      0x2500,
      color_to_tuple(fg),
      color_to_tuple(background),
      0,
    )
  })

  each_index(rect.height, fn(i) {
    buffer.set_cell(
      buf,
      rect.x,
      rect.y + i,
      0x2502,
      color_to_tuple(fg),
      color_to_tuple(background),
      0,
    )
    buffer.set_cell(
      buf,
      rect.x + rect.width - 1,
      rect.y + i,
      0x2502,
      color_to_tuple(fg),
      color_to_tuple(background),
      0,
    )
  })

  buffer.set_cell(
    buf,
    rect.x,
    rect.y,
    0x250c,
    color_to_tuple(fg),
    color_to_tuple(background),
    0,
  )
  buffer.set_cell(
    buf,
    rect.x + rect.width - 1,
    rect.y,
    0x2510,
    color_to_tuple(fg),
    color_to_tuple(background),
    0,
  )
  buffer.set_cell(
    buf,
    rect.x,
    rect.y + rect.height - 1,
    0x2514,
    color_to_tuple(fg),
    color_to_tuple(background),
    0,
  )
  buffer.set_cell(
    buf,
    rect.x + rect.width - 1,
    rect.y + rect.height - 1,
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
        rect.x + 2,
        rect.y,
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
    Box(_, children) | Column(_, children) | Row(_, children) ->
      list.fold(children, next, fn(inner, child) {
        fold_element(child, inner, visit)
      })
    Text(_, _) | Paragraph(_, _) | Spacer(_) -> next
  }
}

fn element_to_string(element: Element) -> String {
  case element {
    Box(styles, children) ->
      "Box("
      <> styles_to_string(styles)
      <> ", ["
      <> children_to_string(children)
      <> "])"
    Column(styles, children) ->
      "Column("
      <> styles_to_string(styles)
      <> ", ["
      <> children_to_string(children)
      <> "])"
    Row(styles, children) ->
      "Row("
      <> styles_to_string(styles)
      <> ", ["
      <> children_to_string(children)
      <> "])"
    Text(styles, content) ->
      "Text(" <> styles_to_string(styles) <> ", \"" <> content <> "\")"
    Paragraph(styles, content) ->
      "Paragraph("
      <> styles_to_string(styles)
      <> ", \""
      <> text.truncate_end(content, 24)
      <> "\")"
    Spacer(height) -> "Spacer(" <> int.to_string(height) <> ")"
  }
}

fn children_to_string(children: List(Element)) -> String {
  children
  |> list.map(element_to_string)
  |> string.join(with: ", ")
}

fn styles_to_string(styles: List(Style)) -> String {
  styles
  |> list.map(fn(style) {
    case style {
      X(value) -> "X(" <> int.to_string(value) <> ")"
      Y(value) -> "Y(" <> int.to_string(value) <> ")"
      Width(value) -> "Width(" <> int.to_string(value) <> ")"
      Height(value) -> "Height(" <> int.to_string(value) <> ")"
      Padding(value) -> "Padding(" <> int.to_string(value) <> ")"
      Gap(value) -> "Gap(" <> int.to_string(value) <> ")"
      Background(_) -> "Background(...)"
      Foreground(_) -> "Foreground(...)"
      Border(title, _) -> "Border(\"" <> title <> "\", ...)"
      Attributes(value) -> "Attributes(" <> int.to_string(value) <> ")"
      Wrap(mode) ->
        case mode {
          text.NoWrap -> "Wrap(NoWrap)"
          text.WordWrap -> "Wrap(WordWrap)"
          text.CharacterWrap -> "Wrap(CharacterWrap)"
        }
      MaxLines(value) -> "MaxLines(" <> int.to_string(value) <> ")"
      Truncate(mode) ->
        case mode {
          NoTruncation -> "Truncate(NoTruncation)"
          EndTruncate -> "Truncate(EndTruncate)"
          MiddleTruncate -> "Truncate(MiddleTruncate)"
        }
    }
  })
  |> string.join(with: ", ")
}
