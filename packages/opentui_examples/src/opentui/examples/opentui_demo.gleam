import gleam/float
import gleam/int
import gleam/list
import opentui/buffer
import opentui/examples/common
import opentui/examples/phase2_state as int_state
import opentui/examples/phase4_state as state
import opentui/examples/phase5_model as model
import opentui/ffi
import opentui/math3d

pub fn main() -> Nil {
  let time = state.create_float(0.0)
  let frame_count = int_state.create_int(0)
  let selected = int_state.create_int(0)

  common.run_animated_demo(
    "OpenTUI Demo",
    "OpenTUI Demo",
    fn(raw) {
      case raw {
        "\t" -> int_state.set_int(selected, { int_state.get_int(selected) + 1 } % 6)
        _ -> Nil
      }
    },
    fn(dt) {
      state.set_float(time, state.get_float(time) +. dt)
      int_state.set_int(frame_count, int_state.get_int(frame_count) + 1)
    },
    fn(buf) { draw(buf, time, frame_count, selected) },
  )
}

fn draw(
  buf: ffi.Buffer,
  time: state.FloatCell,
  frame_count: int_state.IntCell,
  selected: int_state.IntCell,
) -> Nil {
  let t = state.get_float(time)
  let frames = int_state.get_int(frame_count)
  let sel = int_state.get_int(selected)
  let panels = model.showcase_panels()

  draw_panels(buf, panels, sel, t, frames, 0)

  buffer.draw_text(buf,
    " Tab: cycle panels  |  The full OpenTUI Gleam ecosystem",
    4, common.term_h - 1, common.fg_color, common.status_bg, 0)
}

fn draw_panels(
  buf: ffi.Buffer,
  panels: List(model.DemoPanel),
  selected: Int,
  time: Float,
  frames: Int,
  i: Int,
) -> Nil {
  case panels {
    [] -> Nil
    [panel, ..rest] -> {
      let border_fg = case i == selected {
        True -> common.accent_blue
        False -> common.border_fg
      }
      draw_panel_border(buf, panel.x, panel.y, panel.w, panel.h, panel.title, border_fg)
      draw_panel_content(buf, panel, time, frames, i)
      draw_panels(buf, rest, selected, time, frames, i + 1)
    }
  }
}

fn draw_panel_border(
  buf: ffi.Buffer,
  x: Int, y: Int, w: Int, h: Int,
  title: String,
  border_color: #(Float, Float, Float, Float),
) -> Nil {
  buffer.fill_rect(buf, x, y, w, h, common.panel_bg)
  common.each_index(w, fn(i) {
    buffer.set_cell(buf, x + i, y, 0x2500, border_color, common.bg_color, 0)
    buffer.set_cell(buf, x + i, y + h - 1, 0x2500, border_color, common.bg_color, 0)
  })
  common.each_index(h, fn(i) {
    buffer.set_cell(buf, x, y + i, 0x2502, border_color, common.bg_color, 0)
    buffer.set_cell(buf, x + w - 1, y + i, 0x2502, border_color, common.bg_color, 0)
  })
  buffer.set_cell(buf, x, y, 0x250c, border_color, common.bg_color, 0)
  buffer.set_cell(buf, x + w - 1, y, 0x2510, border_color, common.bg_color, 0)
  buffer.set_cell(buf, x, y + h - 1, 0x2514, border_color, common.bg_color, 0)
  buffer.set_cell(buf, x + w - 1, y + h - 1, 0x2518, border_color, common.bg_color, 0)
  buffer.draw_text(buf, " " <> title <> " ", x + 2, y, common.fg_color, common.bg_color, 1)
}

fn draw_panel_content(
  buf: ffi.Buffer,
  panel: model.DemoPanel,
  time: Float,
  frames: Int,
  index: Int,
) -> Nil {
  let x = panel.x + 2
  let y = panel.y + 2
  case index {
    0 -> draw_stats(buf, x, y, time, frames)
    1 -> draw_mini_fractal(buf, x, y, time)
    2 -> draw_anim_bars(buf, x, y, time)
    3 -> draw_unicode_sample(buf, x, y)
    4 -> draw_mini_cube(buf, x, y, time)
    _ -> draw_arch(buf, x, y)
  }
}

fn draw_stats(buf: ffi.Buffer, x: Int, y: Int, time: Float, frames: Int) -> Nil {
  let t_sec = float.truncate(time /. 1000.0)
  buffer.draw_text(buf, "frames: " <> int.to_string(frames), x, y, common.accent_green, common.panel_bg, 0)
  buffer.draw_text(buf, "uptime: " <> int.to_string(t_sec) <> "s", x, y + 1, common.accent_blue, common.panel_bg, 0)
  buffer.draw_text(buf, "packages: 4", x, y + 2, common.fg_color, common.panel_bg, 0)
  buffer.draw_text(buf, "tests: 200+", x, y + 3, common.accent_orange, common.panel_bg, 0)
}

fn draw_mini_fractal(buf: ffi.Buffer, x: Int, y: Int, time: Float) -> Nil {
  let offset = time *. 0.0001
  draw_frac_rows(buf, x, y, offset, 0, 20, 4)
}

fn draw_frac_rows(buf: ffi.Buffer, x: Int, y: Int, offset: Float, row: Int, w: Int, h: Int) -> Nil {
  case row >= h {
    True -> Nil
    False -> {
      draw_frac_cols(buf, x, y, offset, row, 0, w, h)
      draw_frac_rows(buf, x, y, offset, row + 1, w, h)
    }
  }
}

fn draw_frac_cols(buf: ffi.Buffer, x: Int, y: Int, offset: Float, row: Int, col: Int, w: Int, h: Int) -> Nil {
  case col >= w {
    True -> Nil
    False -> {
      let real = -2.0 +. int.to_float(col) /. int.to_float(w) *. 3.0 +. offset
      let imag = -1.0 +. int.to_float(row) /. int.to_float(h) *. 2.0
      let iter = model.mandelbrot(real, imag, 20)
      let #(r, g, b, _) = model.fractal_color(iter, 20)
      buffer.set_cell(buf, x + col, y + row, 0x2588, #(r, g, b, 1.0), common.panel_bg, 0)
      draw_frac_cols(buf, x, y, offset, row, col + 1, w, h)
    }
  }
}

fn draw_anim_bars(buf: ffi.Buffer, x: Int, y: Int, time: Float) -> Nil {
  let t = time /. 1000.0
  draw_bar(buf, x, y, "ease", math3d.sin(t) *. 0.5 +. 0.5, common.accent_green)
  draw_bar(buf, x, y + 1, "lin ", math3d.sin(t *. 1.5) *. 0.5 +. 0.5, common.accent_blue)
  draw_bar(buf, x, y + 2, "bnce", math3d.sin(t *. 0.7) *. 0.5 +. 0.5, common.accent_orange)
  draw_bar(buf, x, y + 3, "fast", math3d.sin(t *. 3.0) *. 0.5 +. 0.5, common.accent_pink)
}

fn draw_bar(buf: ffi.Buffer, x: Int, y: Int, label: String, value: Float, color: #(Float, Float, Float, Float)) -> Nil {
  buffer.draw_text(buf, label, x, y, common.muted_fg, common.panel_bg, 0)
  let bar_w = 14
  let filled = float.truncate(value *. int.to_float(bar_w))
  common.each_index(bar_w, fn(i) {
    let char = case i < filled {
      True -> 0x2588
      False -> 0x2591
    }
    buffer.set_cell(buf, x + 5 + i, y, char, color, common.panel_bg, 0)
  })
}

fn draw_unicode_sample(buf: ffi.Buffer, x: Int, y: Int) -> Nil {
  buffer.draw_text(buf, "東京 北京 서울", x, y, common.fg_color, common.panel_bg, 0)
  buffer.draw_text(buf, "★ ● ◆ ■ ▲ ♦", x, y + 1, common.accent_yellow, common.panel_bg, 0)
  buffer.draw_text(buf, "→ ← ↑ ↓ ∞ ≈", x, y + 2, common.accent_blue, common.panel_bg, 0)
  buffer.draw_text(buf, "½ ⅓ ¼ $ € £ ¥", x, y + 3, common.muted_fg, common.panel_bg, 0)
}

fn draw_mini_cube(buf: ffi.Buffer, x: Int, y: Int, time: Float) -> Nil {
  let angle = time *. 0.001
  let mesh = model.cube_mesh()
  let projected = list.map(mesh.vertices, fn(v) {
    let rotated = math3d.rotate_euler(v, 0.3, angle, 0.0)
    let #(sx, sy) = math3d.project_simple(rotated, 3.5, int.to_float(x) +. 10.0, int.to_float(y) +. 2.0)
    #(float.truncate(sx), float.truncate(sy))
  })
  draw_mini_edges(buf, mesh.edges, projected)
}

fn draw_mini_edges(buf: ffi.Buffer, edges: List(model.Edge), projected: List(#(Int, Int))) -> Nil {
  case edges {
    [] -> Nil
    [edge, ..rest] -> {
      let #(ax, ay) = lat(projected, edge.a)
      let #(bx, by) = lat(projected, edge.b)
      let pts = model.line_points(ax, ay, bx, by)
      draw_pts(buf, pts)
      draw_mini_edges(buf, rest, projected)
    }
  }
}

fn draw_pts(buf: ffi.Buffer, pts: List(#(Int, Int))) -> Nil {
  case pts {
    [] -> Nil
    [#(px, py), ..rest] -> {
      case px >= 2 && px < 78 && py >= 2 && py < 22 {
        True -> buffer.set_cell(buf, px, py, 0xB7, common.accent_green, #(0.0, 0.0, 0.0, 0.0), 0)
        False -> Nil
      }
      draw_pts(buf, rest)
    }
  }
}

fn draw_arch(buf: ffi.Buffer, x: Int, y: Int) -> Nil {
  buffer.draw_text(buf, "core -> runtime", x, y, common.accent_blue, common.panel_bg, 0)
  buffer.draw_text(buf, "runtime -> ui", x, y + 1, common.accent_green, common.panel_bg, 0)
  buffer.draw_text(buf, "all -> examples", x, y + 2, common.accent_orange, common.panel_bg, 0)
  buffer.draw_text(buf, "FP composability", x, y + 3, common.fg_color, common.panel_bg, 1)
}

fn lat(items: List(a), index: Int) -> a {
  case items, index {
    [item, ..], 0 -> item
    [_, ..rest], n -> lat(rest, n - 1)
    [], _ -> panic as "index out of bounds"
  }
}
