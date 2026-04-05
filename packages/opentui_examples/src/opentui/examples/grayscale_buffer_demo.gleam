import opentui/buffer
import opentui/examples/common
import opentui/ffi

pub fn main() -> Nil {
  common.run_static_demo("Grayscale Buffer Demo", "Grayscale Buffer Demo", draw)
}

fn draw(buf: ffi.Buffer) -> Nil {
  common.draw_panel(buf, 2, 3, 76, 18, "Grayscale ramp")
  draw_ramp(buf, 6, 7, 60)
  draw_cells(buf, 6, 13, 10)
  buffer.draw_text(
    buf,
    "The buffer wrapper can already express grayscale studies with plain RGBA fills.",
    6,
    18,
    common.fg_color,
    common.bg_color,
    0,
  )
}

fn draw_ramp(buf: ffi.Buffer, x: Int, y: Int, columns: Int) -> Nil {
  common.each_index(columns, fn(i) {
    let shade = shade_for(i / 6)
    buffer.fill_rect(buf, x + i, y, 1, 3, #(shade, shade, shade, 1.0))
  })
}

fn draw_cells(buf: ffi.Buffer, x: Int, y: Int, columns: Int) -> Nil {
  common.each_index(columns, fn(i) {
    let shade = shade_for(i)
    let left = x + i * 6
    buffer.fill_rect(buf, left, y, 5, 3, #(shade, shade, shade, 1.0))
    buffer.draw_text(
      buf,
      label_for(i),
      left + 1,
      y + 1,
      contrast_for(i),
      #(shade, shade, shade, 1.0),
      1,
    )
  })
}

fn contrast_for(index: Int) -> #(Float, Float, Float, Float) {
  case index > 5 {
    True -> common.bg_color
    False -> common.fg_color
  }
}

fn shade_for(index: Int) -> Float {
  case index {
    0 -> 0.05
    1 -> 0.15
    2 -> 0.25
    3 -> 0.35
    4 -> 0.45
    5 -> 0.55
    6 -> 0.65
    7 -> 0.75
    8 -> 0.85
    _ -> 0.95
  }
}

fn label_for(i: Int) -> String {
  case i {
    0 -> "0"
    1 -> "1"
    2 -> "2"
    3 -> "3"
    4 -> "4"
    5 -> "5"
    6 -> "6"
    7 -> "7"
    8 -> "8"
    _ -> "9"
  }
}
