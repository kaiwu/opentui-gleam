import gleam/float
import gleam/int
import opentui/animation
import opentui/buffer
import opentui/examples/common
import opentui/examples/phase4_model as model
import opentui/examples/phase4_state as state
import opentui/ffi
import opentui/framebuffer

pub fn main() -> Nil {
  let time = state.create_float(0.0)
  let frame_idx = state.create_float(0.0)

  common.run_animated_demo(
    "Sprite Animation Demo",
    "Sprite Animation Demo",
    fn(_key) { Nil },
    fn(dt) {
      state.set_float(time, state.get_float(time) +. dt)
      // Switch frame every 200ms, 4 frames total
      let fi = state.get_float(time) /. 200.0
      let frame = fi -. int.to_float(float.truncate(fi /. 4.0)) *. 4.0
      state.set_float(frame_idx, frame)
    },
    fn(buf) { draw(buf, time, frame_idx) },
  )
}

fn draw(buf: ffi.Buffer, time: state.FloatCell, frame_idx: state.FloatCell) -> Nil {
  let t = state.get_float(time)
  let frame = float.truncate(state.get_float(frame_idx))

  common.draw_panel(buf, 2, 2, 76, 19, "Sprite Animation (TUI Fallback)")

  // Build timeline for bouncing motion
  let tl =
    animation.create(2000.0, True)
    |> animation.add_tween(
      "y",
      0.0,
      animation.Tween(
        from: 0.0,
        to: 8.0,
        duration: 2000.0,
        easing: animation.ease_out_bounce,
      ),
    )
  let tl = animation.tick(tl, t -. int.to_float(float.truncate(t /. 2000.0)) *. 2000.0)
  let y_offset = float.truncate(animation.value(tl, "y"))

  // Draw 4 animation frames side by side
  draw_animation_frames(buf, frame, 6, 5)

  // Draw active frame at animated position
  let assert Ok(sprite) = framebuffer.create(8, 5, "anim_sprite")
  let hue = int.to_float(frame * 90)
  let color = model.hue_to_rgb(hue)
  draw_frame_shape(sprite, frame, color)
  framebuffer.draw_onto(buf, 50, 5 + y_offset, sprite)
  framebuffer.destroy(sprite)

  buffer.draw_text(buf, "<- spritesheet frames", 6, 13, common.muted_fg, common.panel_bg, 0)
  buffer.draw_text(buf, "active ->", 40, 8, common.accent_blue, common.panel_bg, 1)
  buffer.draw_text(
    buf,
    "frame: " <> int.to_string(frame) <> "/4  t=" <> int.to_string(float.truncate(t)) <> "ms",
    6,
    15,
    common.fg_color,
    common.panel_bg,
    0,
  )
  buffer.draw_text(buf, "Bounce easing + frame cycling", 6, 17, common.muted_fg, common.panel_bg, 0)
}

fn draw_animation_frames(buf: ffi.Buffer, active: Int, x: Int, y: Int) -> Nil {
  draw_frame_at(buf, 0, active, x, y)
  draw_frame_at(buf, 1, active, x + 9, y)
  draw_frame_at(buf, 2, active, x + 18, y)
  draw_frame_at(buf, 3, active, x + 27, y)
}

fn draw_frame_at(buf: ffi.Buffer, idx: Int, active: Int, x: Int, y: Int) -> Nil {
  let border_color = case idx == active {
    True -> common.accent_green
    False -> common.border_fg
  }
  let hue = int.to_float(idx * 90)
  let color = model.hue_to_rgb(hue)

  common.each_index(8, fn(i) {
    buffer.set_cell(buf, x + i, y, 0x2500, border_color, common.panel_bg, 0)
    buffer.set_cell(buf, x + i, y + 6, 0x2500, border_color, common.panel_bg, 0)
  })
  common.each_index(7, fn(i) {
    buffer.set_cell(buf, x, y + i, 0x2502, border_color, common.panel_bg, 0)
    buffer.set_cell(buf, x + 7, y + i, 0x2502, border_color, common.panel_bg, 0)
  })

  draw_frame_shape_inline(buf, idx, x + 1, y + 1, color)
}

fn draw_frame_shape_inline(
  buf: ffi.Buffer,
  frame: Int,
  x: Int,
  y: Int,
  color: #(Float, Float, Float, Float),
) -> Nil {
  let pixels = frame_pixels(frame)
  draw_pixel_list(buf, pixels, x, y, color)
}

fn draw_frame_shape(
  fb: ffi.Buffer,
  frame: Int,
  color: #(Float, Float, Float, Float),
) -> Nil {
  let pixels = frame_pixels(frame)
  draw_pixel_list(fb, pixels, 0, 0, color)
}

fn frame_pixels(frame: Int) -> List(#(Int, Int)) {
  case frame {
    0 -> [#(2, 0), #(3, 0), #(1, 1), #(2, 1), #(3, 1), #(4, 1), #(2, 2), #(3, 2), #(1, 3), #(4, 3)]
    1 -> [#(3, 0), #(2, 1), #(3, 1), #(4, 1), #(1, 2), #(2, 2), #(3, 2), #(4, 2), #(2, 3), #(3, 3)]
    2 -> [#(2, 0), #(3, 0), #(1, 1), #(2, 1), #(3, 1), #(4, 1), #(2, 2), #(3, 2), #(2, 3), #(3, 3)]
    _ -> [#(2, 0), #(1, 1), #(2, 1), #(3, 1), #(4, 1), #(2, 2), #(3, 2), #(4, 2), #(3, 3), #(2, 3)]
  }
}

fn draw_pixel_list(
  buf: ffi.Buffer,
  pixels: List(#(Int, Int)),
  ox: Int,
  oy: Int,
  color: #(Float, Float, Float, Float),
) -> Nil {
  case pixels {
    [] -> Nil
    [#(x, y), ..rest] -> {
      buffer.set_cell(buf, ox + x, oy + y, 0x2588, color, #(0.0, 0.0, 0.0, 0.0), 0)
      draw_pixel_list(buf, rest, ox, oy, color)
    }
  }
}
