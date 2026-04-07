import gleam/float
import gleam/int
import opentui/animation
import opentui/buffer
import opentui/examples/common
import opentui/examples/phase2_state as int_state
import opentui/examples/phase4_model as model
import opentui/examples/phase4_state as state
import opentui/ffi

pub fn main() -> Nil {
  let tl_elapsed = state.create_float(0.0)
  let loop_count = int_state.create_int(0)
  let duration = 4000.0

  common.run_animated_demo(
    "Timeline Example",
    "Timeline Example",
    fn(_key) { Nil },
    fn(dt) { tick(tl_elapsed, loop_count, duration, dt) },
    fn(buf) { draw(buf, tl_elapsed, loop_count, duration) },
  )
}

fn tick(
  tl_elapsed: state.FloatCell,
  loop_count: int_state.IntCell,
  duration: Float,
  dt_ms: Float,
) -> Nil {
  let new_elapsed = state.get_float(tl_elapsed) +. dt_ms
  case new_elapsed >=. duration {
    True -> {
      state.set_float(tl_elapsed, new_elapsed -. duration)
      int_state.set_int(loop_count, int_state.get_int(loop_count) + 1)
    }
    False -> state.set_float(tl_elapsed, new_elapsed)
  }
}

fn draw(
  buf: ffi.Buffer,
  tl_elapsed: state.FloatCell,
  loop_count: int_state.IntCell,
  duration: Float,
) -> Nil {
  let elapsed = state.get_float(tl_elapsed)

  // Build a timeline with two tweens
  let tl =
    animation.create(duration, True)
    |> animation.add_tween(
      "x",
      0.0,
      animation.Tween(
        from: 4.0,
        to: 70.0,
        duration: duration,
        easing: animation.ease_in_out,
      ),
    )
    |> animation.add_tween(
      "hue",
      0.0,
      animation.Tween(
        from: 0.0,
        to: 360.0,
        duration: duration,
        easing: animation.linear,
      ),
    )

  // Set elapsed
  let tl = animation.tick(tl, elapsed)

  let x_val = animation.value(tl, "x")
  let hue_val = animation.value(tl, "hue")
  let progress = animation.progress(tl)
  let loops = int_state.get_int(loop_count)

  // Progress bar
  common.draw_panel(buf, 2, 2, 76, 5, "Timeline Progress")
  let bar_width = 68
  let filled = float.truncate(progress *. int.to_float(bar_width))
  draw_progress_bar(buf, 6, 4, bar_width, filled)
  buffer.draw_text(
    buf,
    model.float_to_string_1(progress *. 100.0) <> "%",
    68,
    4,
    common.accent_blue,
    common.panel_bg,
    1,
  )

  // Moving box driven by "x" tween
  common.draw_panel(buf, 2, 8, 76, 5, "Tween: x (ease-in-out)")
  let box_x = float.truncate(x_val)
  buffer.fill_rect(buf, box_x, 10, 6, 2, common.accent_blue)
  buffer.draw_text(buf, " ■■ ", box_x + 1, 10, common.fg_color, common.accent_blue, 1)

  // Color panel driven by "hue" tween
  common.draw_panel(buf, 2, 14, 76, 5, "Tween: hue (linear)")
  let #(r, g, b, _) = model.hue_to_rgb(hue_val)
  let color = #(r, g, b, 1.0)
  buffer.fill_rect(buf, 6, 16, 20, 2, color)
  buffer.draw_text(
    buf,
    "hue: " <> int.to_string(float.truncate(hue_val)) <> "°",
    28,
    16,
    common.fg_color,
    common.panel_bg,
    0,
  )

  // Info
  buffer.draw_text(
    buf,
    " elapsed: "
      <> model.float_to_string_1(elapsed)
      <> "ms  loops: "
      <> int.to_string(loops)
      <> "  x="
      <> int.to_string(float.truncate(x_val))
      <> "  hue="
      <> int.to_string(float.truncate(hue_val)),
    4,
    common.term_h - 1,
    common.fg_color,
    common.status_bg,
    0,
  )
}

fn draw_progress_bar(
  buf: ffi.Buffer,
  x: Int,
  y: Int,
  width: Int,
  filled: Int,
) -> Nil {
  common.each_index(width, fn(i) {
    case i < filled {
      True ->
        buffer.set_cell(
          buf,
          x + i,
          y,
          0x2588,
          common.accent_green,
          common.panel_bg,
          0,
        )
      False ->
        buffer.set_cell(
          buf,
          x + i,
          y,
          0x2591,
          common.muted_fg,
          common.panel_bg,
          0,
        )
    }
  })
}
