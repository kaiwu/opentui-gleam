import gleam/float
import gleam/int
import opentui/animation
import opentui/buffer
import opentui/examples/common
import opentui/examples/phase4_model as model
import opentui/examples/phase4_state as state
import opentui/examples/sprite_animation_demo_model as anim_model
import opentui/ffi
import opentui/framebuffer

/// Sprite Animation Demo
/// 
/// Demonstrates sprite-sheet animation with:
/// - Frame cycling from a 4-frame sprite sheet
/// - Interactive controls: pause, step, speed adjustment, reset
/// - Bounce easing tied to animation state
/// - Sprite sheet strip preview with active frame highlighting
/// 
/// Controls:
///   Space     - Pause/Resume
///   . or n    - Single-step (when paused or running)
///   + or =    - Increase speed (shorter frame duration)
///   -         - Decrease speed (longer frame duration)
///   r         - Reset to frame 0, running state
///   q/Ctrl+C  - Quit
pub fn main() -> Nil {
  // Mutable state cell for animator
  let anim_cell = state.create_generic(anim_model.create(4))

  common.run_animated_demo(
    "Sprite Animation Demo",
    "Sprite Animation Demo",
    fn(key) { handle_key(anim_cell, key) },
    fn(dt) {
      // Tick animator forward
      let anim = state.get_generic(anim_cell)
      let anim = anim_model.tick(anim, dt)
      state.set_generic(anim_cell, anim)
    },
    fn(buf) { draw(buf, anim_cell) },
  )
}

fn handle_key(anim_cell: state.GenericCell, key: String) -> Nil {
  let anim = state.get_generic(anim_cell)
  let new_anim = case key {
    // Pause/Resume - Space or p
    " " | "p" -> anim_model.toggle_running(anim)
    // Single-step - . or n
    "." | "n" -> anim_model.step_frame(anim)
    // Increase speed - + or =
    "+" | "=" -> anim_model.increase_speed(anim)
    // Decrease speed - -
    "-" -> anim_model.decrease_speed(anim)
    // Reset - r
    "r" -> anim_model.reset(anim)
    // Ignore other keys
    _ -> anim
  }
  state.set_generic(anim_cell, new_anim)
}

fn draw(buf: ffi.Buffer, anim_cell: state.GenericCell) -> Nil {
  let anim = state.get_generic(anim_cell)
  let frame = anim_model.current_frame(anim)

  // Main panel
  common.draw_panel(buf, 2, 2, 76, 19, "Sprite Animation Demo")

  // Draw sprite sheet strip (4 frames side by side)
  draw_sprite_sheet_strip(buf, frame, 6, 5)

  // Draw active sprite at bounce-eased position
  draw_active_sprite(buf, frame, anim)

  // Status line showing frame, state, speed
  let status = anim_model.format_status(anim)
  buffer.draw_text(buf, status, 6, 15, common.fg_color, common.panel_bg, 0)

  // Instructions line
  let instructions = "Space: pause  n/.: step  +/-: speed  r: reset"
  buffer.draw_text(
    buf,
    instructions,
    6,
    17,
    common.muted_fg,
    common.panel_bg,
    0,
  )
}

/// Draw the 4-frame sprite sheet as a horizontal strip.
/// Active frame is highlighted with accent color border.
fn draw_sprite_sheet_strip(buf: ffi.Buffer, active: Int, x: Int, y: Int) -> Nil {
  draw_frame_at(buf, 0, active, x, y, "0")
  draw_frame_at(buf, 1, active, x + 9, y, "1")
  draw_frame_at(buf, 2, active, x + 18, y, "2")
  draw_frame_at(buf, 3, active, x + 27, y, "3")

  // Label
  buffer.draw_text(
    buf,
    "sprite sheet",
    6,
    12,
    common.muted_fg,
    common.panel_bg,
    0,
  )
}

/// Draw a single frame in the strip with border and label.
fn draw_frame_at(
  buf: ffi.Buffer,
  idx: Int,
  active: Int,
  x: Int,
  y: Int,
  label: String,
) -> Nil {
  let is_active = idx == active
  let border_color = case is_active {
    True -> common.accent_green
    False -> common.border_fg
  }
  let hue = int.to_float(idx * 90)
  let color = model.hue_to_rgb(hue)

  // Border box
  common.each_index(8, fn(i) {
    buffer.set_cell(buf, x + i, y, 0x2500, border_color, common.panel_bg, 0)
    buffer.set_cell(buf, x + i, y + 6, 0x2500, border_color, common.panel_bg, 0)
  })
  common.each_index(7, fn(i) {
    buffer.set_cell(buf, x, y + i, 0x2502, border_color, common.panel_bg, 0)
    buffer.set_cell(buf, x + 7, y + i, 0x2502, border_color, common.panel_bg, 0)
  })

  // Frame pixels
  draw_frame_shape_inline(buf, idx, x + 1, y + 1, color)

  // Frame number label
  buffer.draw_text(buf, label, x + 3, y + 7, border_color, common.panel_bg, 0)
}

/// Draw a frame's pixel shape directly into a buffer.
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

/// Draw the active sprite at bounce-eased position.
fn draw_active_sprite(
  buf: ffi.Buffer,
  frame: Int,
  anim: anim_model.Animator,
) -> Nil {
  let assert Ok(sprite) = framebuffer.create(8, 5, "active_sprite")
  let hue = int.to_float(frame * 90)
  let color = model.hue_to_rgb(hue)
  draw_frame_shape(sprite, frame, color)

  // Bounce easing tied to animation elapsed time
  // Cycle every 2000ms for smooth bounce motion
  let cycle_time = 2000.0
  let anim_elapsed = anim_model.get_elapsed_ms(anim)
  let local_t =
    anim_elapsed
    -. int.to_float(float.truncate(anim_elapsed /. cycle_time))
    *. cycle_time
  let y_offset = case anim_model.is_running(anim) {
    True -> bounce_ease(local_t)
    False -> bounce_ease(anim_elapsed)
    // Frozen position when paused
  }

  framebuffer.draw_onto(buf, 50, 5 + y_offset, sprite)
  framebuffer.destroy(sprite)

  // Active sprite label
  buffer.draw_text(
    buf,
    "active",
    50,
    12,
    common.accent_blue,
    common.panel_bg,
    0,
  )
}

/// Compute bounce-eased vertical offset.
fn bounce_ease(t: Float) -> Int {
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
  let tl = animation.tick(tl, t)
  float.truncate(animation.value(tl, "y"))
}

/// Draw a frame's pixel shape into a framebuffer.
fn draw_frame_shape(
  fb: ffi.Buffer,
  frame: Int,
  color: #(Float, Float, Float, Float),
) -> Nil {
  let pixels = frame_pixels(frame)
  draw_pixel_list(fb, pixels, 0, 0, color)
}

/// Pixel coordinates for each animation frame.
/// Returns list of (x, y) positions within 6x5 frame area.
fn frame_pixels(frame: Int) -> List(#(Int, Int)) {
  case frame {
    // Frame 0: diamond-like shape
    0 -> [
      #(2, 0),
      #(3, 0),
      #(1, 1),
      #(2, 1),
      #(3, 1),
      #(4, 1),
      #(2, 2),
      #(3, 2),
      #(1, 3),
      #(4, 3),
    ]
    // Frame 1: shifted diamond
    1 -> [
      #(3, 0),
      #(2, 1),
      #(3, 1),
      #(4, 1),
      #(1, 2),
      #(2, 2),
      #(3, 2),
      #(4, 2),
      #(2, 3),
      #(3, 3),
    ]
    // Frame 2: cross shape
    2 -> [
      #(2, 0),
      #(3, 0),
      #(1, 1),
      #(2, 1),
      #(3, 1),
      #(4, 1),
      #(2, 2),
      #(3, 2),
      #(2, 3),
      #(3, 3),
    ]
    // Frame 3: inverted shape
    _ -> [
      #(2, 0),
      #(1, 1),
      #(2, 1),
      #(3, 1),
      #(4, 1),
      #(2, 2),
      #(3, 2),
      #(4, 2),
      #(3, 3),
      #(2, 3),
    ]
  }
}

/// Draw a list of pixels at given offset with specified color.
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
      buffer.set_cell(
        buf,
        ox + x,
        oy + y,
        0x2588,
        color,
        #(0.0, 0.0, 0.0, 0.0),
        0,
      )
      draw_pixel_list(buf, rest, ox, oy, color)
    }
  }
}
