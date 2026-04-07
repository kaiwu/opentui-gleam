import gleam/float
import gleam/int
import opentui/buffer
import opentui/examples/common
import opentui/examples/phase4_model as model
import opentui/examples/phase4_state as state
import opentui/ffi
import opentui/framebuffer

pub fn main() -> Nil {
  let ball_x = state.create_float(20.0)
  let ball_y = state.create_float(10.0)
  let ball_vx = state.create_float(15.0)
  let ball_vy = state.create_float(8.0)
  let box_x = state.create_float(5.0)
  let box_vx = state.create_float(10.0)
  let frame_count = state.create_float(0.0)

  common.run_animated_demo(
    "Framebuffer Demo",
    "Framebuffer Demo",
    fn(_key) { Nil },
    fn(dt) {
      tick(ball_x, ball_y, ball_vx, ball_vy, box_x, box_vx, frame_count, dt)
    },
    fn(buf) {
      draw(buf, ball_x, ball_y, box_x, frame_count)
    },
  )
}

fn tick(
  ball_x: state.FloatCell,
  ball_y: state.FloatCell,
  ball_vx: state.FloatCell,
  ball_vy: state.FloatCell,
  box_x: state.FloatCell,
  box_vx: state.FloatCell,
  frame_count: state.FloatCell,
  dt_ms: Float,
) -> Nil {
  let dt = dt_ms /. 1000.0

  let #(bx, bvx) =
    model.bounce_step(
      state.get_float(ball_x),
      state.get_float(ball_vx),
      dt,
      0.0,
      70.0,
    )
  let #(by, bvy) =
    model.bounce_step(
      state.get_float(ball_y),
      state.get_float(ball_vy),
      dt,
      0.0,
      18.0,
    )
  state.set_float(ball_x, bx)
  state.set_float(ball_y, by)
  state.set_float(ball_vx, bvx)
  state.set_float(ball_vy, bvy)

  let #(rx, rvx) =
    model.bounce_step(
      state.get_float(box_x),
      state.get_float(box_vx),
      dt,
      0.0,
      60.0,
    )
  state.set_float(box_x, rx)
  state.set_float(box_vx, rvx)

  state.set_float(frame_count, state.get_float(frame_count) +. 1.0)
}

fn draw(
  buf: ffi.Buffer,
  ball_x: state.FloatCell,
  ball_y: state.FloatCell,
  box_x: state.FloatCell,
  frame_count: state.FloatCell,
) -> Nil {
  // Background pattern framebuffer
  let assert Ok(bg_fb) = framebuffer.create(76, 20, "fb_bg")
  draw_background_pattern(bg_fb, 76, 20)
  framebuffer.draw_onto(buf, 2, 2, bg_fb)
  framebuffer.destroy(bg_fb)

  // Moving box framebuffer
  let assert Ok(box_fb) = framebuffer.create(12, 5, "fb_box")
  buffer.fill_rect(box_fb, 0, 0, 12, 5, #(0.2, 0.5, 0.9, 0.8))
  buffer.draw_text(box_fb, "  moving  ", 1, 1, common.fg_color, #(0.2, 0.5, 0.9, 0.8), 1)
  buffer.draw_text(box_fb, "   box    ", 1, 2, common.fg_color, #(0.2, 0.5, 0.9, 0.8), 0)
  buffer.draw_text(box_fb, "  region  ", 1, 3, common.muted_fg, #(0.2, 0.5, 0.9, 0.8), 0)
  let bx_int = float.truncate(state.get_float(box_x))
  framebuffer.draw_onto(buf, 2 + bx_int, 6, box_fb)
  framebuffer.destroy(box_fb)

  // Bouncing ball
  let px = float.truncate(state.get_float(ball_x))
  let py = float.truncate(state.get_float(ball_y))
  buffer.set_cell(buf, 2 + px, 2 + py, 0x25CF, #(1.0, 0.3, 0.3, 1.0), #(0.0, 0.0, 0.0, 0.0), 0)

  // Transparent overlay
  let assert Ok(overlay) = framebuffer.create(30, 3, "fb_overlay")
  buffer.fill_rect(overlay, 0, 0, 30, 3, #(0.0, 0.0, 0.0, 0.5))
  buffer.draw_text(overlay, " Framebuffer Compositing ", 2, 1, common.accent_green, #(0.0, 0.0, 0.0, 0.5), 1)
  framebuffer.draw_onto(buf, 25, 3, overlay)
  framebuffer.destroy(overlay)

  // Info bar
  let frames = float.truncate(state.get_float(frame_count))
  buffer.draw_text(
    buf,
    " frames: "
      <> int.to_string(frames)
      <> "  ball: ("
      <> int.to_string(px)
      <> ","
      <> int.to_string(py)
      <> ")  box_x: "
      <> int.to_string(bx_int),
    4,
    common.term_h - 1,
    common.fg_color,
    common.status_bg,
    0,
  )
}

fn draw_background_pattern(fb: ffi.Buffer, w: Int, h: Int) -> Nil {
  draw_bg_rows(fb, 0, w, h)
}

fn draw_bg_rows(fb: ffi.Buffer, y: Int, w: Int, h: Int) -> Nil {
  case y >= h {
    True -> Nil
    False -> {
      draw_bg_cols(fb, 0, y, w)
      draw_bg_rows(fb, y + 1, w, h)
    }
  }
}

fn draw_bg_cols(fb: ffi.Buffer, x: Int, y: Int, w: Int) -> Nil {
  case x >= w {
    True -> Nil
    False -> {
      let color = model.pattern_color(x, y)
      let char = model.pattern_char(x, y)
      let cp = case char {
        "·" -> 0xB7
        "+" -> 0x2B
        "×" -> 0xD7
        "○" -> 0x25CB
        _ -> 0xB7
      }
      buffer.set_cell(fb, x, y, cp, color, common.bg_color, 0)
      draw_bg_cols(fb, x + 1, y, w)
    }
  }
}
