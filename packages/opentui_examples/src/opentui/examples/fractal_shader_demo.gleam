import gleam/float
import gleam/int
import opentui/buffer
import opentui/examples/common
import opentui/examples/phase4_state as state
import opentui/examples/phase5_model as model
import opentui/ffi

pub fn main() -> Nil {
  let time = state.create_float(0.0)

  common.run_animated_demo(
    "Fractal Shader Demo",
    "Fractal Shader Demo",
    fn(_key) { Nil },
    fn(dt) { state.set_float(time, state.get_float(time) +. dt) },
    fn(buf) { draw(buf, time) },
  )
}

fn draw(buf: ffi.Buffer, time: state.FloatCell) -> Nil {
  let t = state.get_float(time) *. 0.0003

  // Viewport pans slowly through the fractal
  let cx = -0.5 +. t *. 0.1
  let cy = 0.0 +. t *. 0.05
  let zoom = 2.5 -. t *. 0.3

  let clamped_zoom = case zoom <. 0.5 {
    True -> 0.5
    False -> zoom
  }

  let w = 76
  let h = 18
  let max_iter = 40

  draw_fractal_rows(buf, cx, cy, clamped_zoom, w, h, max_iter, 0)

  buffer.draw_text(
    buf,
    " Mandelbrot  zoom="
      <> float_str(clamped_zoom)
      <> "  center=("
      <> float_str(cx)
      <> ","
      <> float_str(cy)
      <> ")",
    4,
    common.term_h - 1,
    common.fg_color,
    common.status_bg,
    0,
  )
}

fn draw_fractal_rows(
  buf: ffi.Buffer,
  cx: Float,
  cy: Float,
  zoom: Float,
  w: Int,
  h: Int,
  max_iter: Int,
  row: Int,
) -> Nil {
  case row >= h {
    True -> Nil
    False -> {
      draw_fractal_cols(buf, cx, cy, zoom, w, h, max_iter, row, 0)
      draw_fractal_rows(buf, cx, cy, zoom, w, h, max_iter, row + 1)
    }
  }
}

fn draw_fractal_cols(
  buf: ffi.Buffer,
  cx: Float,
  cy: Float,
  zoom: Float,
  w: Int,
  h: Int,
  max_iter: Int,
  row: Int,
  col: Int,
) -> Nil {
  case col >= w {
    True -> Nil
    False -> {
      // Map screen position to complex plane
      let real =
        cx +. { int.to_float(col) -. int.to_float(w) /. 2.0 }
        /. int.to_float(w) *. zoom *. 2.5
      let imag =
        cy +. { int.to_float(row) -. int.to_float(h) /. 2.0 }
        /. int.to_float(h) *. zoom *. 2.0

      let iter = model.mandelbrot(real, imag, max_iter)
      let char = model.fractal_char(iter, max_iter)
      let #(r, g, b, _a) = model.fractal_color(iter, max_iter)

      buffer.set_cell(
        buf,
        2 + col,
        3 + row,
        char,
        #(r, g, b, 1.0),
        common.bg_color,
        0,
      )

      draw_fractal_cols(buf, cx, cy, zoom, w, h, max_iter, row, col + 1)
    }
  }
}

fn float_str(f: Float) -> String {
  let whole = float.truncate(f)
  let frac =
    float.truncate(
      { f -. int.to_float(whole) }
      *. 100.0,
    )
  int.to_string(whole) <> "." <> int.to_string(int.absolute_value(frac))
}
