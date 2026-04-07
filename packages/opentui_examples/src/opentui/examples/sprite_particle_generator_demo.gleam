import gleam/float
import gleam/int
import opentui/buffer
import opentui/examples/common
import opentui/examples/phase4_model as model
import opentui/examples/phase4_state as state
import opentui/ffi
import opentui/framebuffer

pub fn main() -> Nil {
  let time = state.create_float(0.0)

  common.run_animated_demo(
    "Sprite Particle Generator Demo",
    "Sprite Particle Generator Demo",
    fn(_key) { Nil },
    fn(dt) { state.set_float(time, state.get_float(time) +. dt) },
    fn(buf) { draw(buf, time) },
  )
}

fn draw(buf: ffi.Buffer, time: state.FloatCell) -> Nil {
  let t = state.get_float(time)

  common.draw_panel(buf, 2, 2, 76, 19, "Particle Generator (TUI Fallback)")

  // Draw particle field using a framebuffer
  let assert Ok(field) = framebuffer.create(70, 16, "particles")
  buffer.fill_rect(field, 0, 0, 70, 16, #(0.02, 0.02, 0.05, 1.0))
  draw_particles(field, t, 0, 24)
  framebuffer.draw_onto(buf, 5, 4, field)
  framebuffer.destroy(field)

  // Stats
  buffer.draw_text(
    buf,
    " particles: 24  t=" <> int.to_string(float.truncate(t)) <> "ms",
    4,
    common.term_h - 1,
    common.fg_color,
    common.status_bg,
    0,
  )
}

fn draw_particles(
  fb: ffi.Buffer,
  time: Float,
  i: Int,
  count: Int,
) -> Nil {
  case i >= count {
    True -> Nil
    False -> {
      // Each particle has a unique phase and speed
      let phase = int.to_float(i * 137)
      let speed_x = 0.008 +. int.to_float(i % 5) *. 0.003
      let speed_y = 0.005 +. int.to_float(i % 3) *. 0.004

      let raw_x = phase +. time *. speed_x
      let raw_y = int.to_float(i * 47) +. time *. speed_y

      // Wrap within field
      let x = float.truncate(raw_x) % 70
      let y = float.truncate(raw_y) % 16
      let px = case x < 0 {
        True -> x + 70
        False -> x
      }
      let py = case y < 0 {
        True -> y + 16
        False -> y
      }

      // Color from particle index
      let hue = int.to_float({ i * 15 } % 360) +. time *. 0.02
      let #(r, g, b, _) = model.hue_to_rgb(hue)

      // Brightness varies per particle
      let brightness = 0.5 +. int.to_float(i % 3) *. 0.2
      let char = case i % 4 {
        0 -> 0x2022
        1 -> 0x25CF
        2 -> 0x2726
        _ -> 0x00B7
      }

      buffer.set_cell(
        fb,
        px,
        py,
        char,
        #(r *. brightness, g *. brightness, b *. brightness, 1.0),
        #(0.0, 0.0, 0.0, 0.0),
        0,
      )

      draw_particles(fb, time, i + 1, count)
    }
  }
}
