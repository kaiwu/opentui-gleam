import gleam/float
import opentui/buffer
import opentui/examples/common
import opentui/examples/phase4_model as model
import opentui/examples/phase4_state as state
import opentui/examples/sprite_particle_generator_demo_model as particle_model
import opentui/ffi
import opentui/framebuffer

/// Particle Generator Demo
///
/// Demonstrates a particle generator system with:
/// - Multiple presets (Fountain, Sparkle) with distinct behaviors
/// - Interactive controls: burst, auto emission, stop, clear, mode switch
/// - Physics-like motion with gravity and finite lifetimes
/// - Visual feedback: framed emitter area, status display, instructions
///
/// Controls:
///   b         - Burst: spawn a batch of particles immediately
///   a         - Toggle auto emission mode (continuous spawning)
///   s         - Stop emission (pause spawning)
///   m         - Switch to next preset/mode
///   x         - Clear all particles
///   r         - Reset to initial state
///   q/Ctrl+C  - Quit
pub fn main() -> Nil {
  // Mutable state cell for particle system
  let system_cell = state.create_generic(particle_model.create())

  common.run_animated_demo(
    "Particle Generator Demo",
    "Particle Generator Demo",
    fn(key) { handle_key(system_cell, key) },
    fn(dt) {
      // Tick particle system forward
      let system = state.get_generic(system_cell)
      let system = particle_model.tick(system, dt)
      state.set_generic(system_cell, system)
    },
    fn(buf) { draw(buf, system_cell) },
  )
}

fn handle_key(system_cell: state.GenericCell, key: String) -> Nil {
  let system = state.get_generic(system_cell)
  let new_system = case key {
    // Burst
    "b" -> particle_model.burst(system)
    // Toggle auto emission
    "a" -> particle_model.toggle_auto(system)
    // Stop emission
    "s" -> particle_model.stop_emission(system)
    // Next preset/mode
    "m" -> particle_model.next_preset(system)
    // Clear all particles
    "x" -> particle_model.clear(system)
    // Reset
    "r" -> particle_model.reset(system)
    // Ignore other keys
    _ -> system
  }
  state.set_generic(system_cell, new_system)
}

fn draw(buf: ffi.Buffer, system_cell: state.GenericCell) -> Nil {
  let system = state.get_generic(system_cell)

  // Main panel with framed emitter area
  common.draw_panel(buf, 2, 2, 76, 19, "Particle Generator")

  // Draw emitter frame inside the panel
  draw_emitter_frame(buf, 5, 4, 70, 14)

  // Draw particles within the emitter area using a framebuffer
  let assert Ok(field) = framebuffer.create(68, 12, "particles")
  buffer.fill_rect(field, 0, 0, 68, 12, #(0.02, 0.02, 0.05, 1.0))
  draw_particles(field, system, 34.0, 6.0)
  framebuffer.draw_onto(buf, 6, 5, field)
  framebuffer.destroy(field)

  // Status line showing preset, auto/idle state, and particle count
  let status = particle_model.format_status(system)
  buffer.draw_text(buf, status, 5, 18, common.fg_color, common.panel_bg, 0)

  // Instructions line
  let instructions = particle_model.format_instructions()
  buffer.draw_text(
    buf,
    instructions,
    5,
    common.term_h - 1,
    common.muted_fg,
    common.status_bg,
    0,
  )
}

/// Draw a framed emitter area with labeled corners.
fn draw_emitter_frame(buf: ffi.Buffer, x: Int, y: Int, w: Int, h: Int) -> Nil {
  // Top and bottom edges
  common.each_index(w, fn(i) {
    buffer.set_cell(buf, x + i, y, 0x2500, common.border_fg, common.panel_bg, 0)
    buffer.set_cell(
      buf,
      x + i,
      y + h - 1,
      0x2500,
      common.border_fg,
      common.panel_bg,
      0,
    )
  })

  // Left and right edges
  common.each_index(h, fn(i) {
    buffer.set_cell(buf, x, y + i, 0x2502, common.border_fg, common.panel_bg, 0)
    buffer.set_cell(
      buf,
      x + w - 1,
      y + i,
      0x2502,
      common.border_fg,
      common.panel_bg,
      0,
    )
  })

  // Corner characters
  buffer.set_cell(buf, x, y, 0x250c, common.border_fg, common.panel_bg, 0)
  buffer.set_cell(
    buf,
    x + w - 1,
    y,
    0x2510,
    common.border_fg,
    common.panel_bg,
    0,
  )
  buffer.set_cell(
    buf,
    x,
    y + h - 1,
    0x2514,
    common.border_fg,
    common.panel_bg,
    0,
  )
  buffer.set_cell(
    buf,
    x + w - 1,
    y + h - 1,
    0x2518,
    common.border_fg,
    common.panel_bg,
    0,
  )

  // Emitter center marker
  let center_x = x + w / 2 - 2
  let center_y = y + h / 2
  buffer.draw_text(
    buf,
    "∧",
    center_x,
    center_y,
    common.accent_yellow,
    common.panel_bg,
    0,
  )
}

/// Draw all particles in the emitter area.
/// Particles are positioned relative to emitter center, then clamped to bounds.
fn draw_particles(
  fb: ffi.Buffer,
  system: particle_model.System,
  emitter_center_x: Float,
  emitter_center_y: Float,
) -> Nil {
  let particles = particle_model.get_particles(system)
  let min_x = 0.0
  let max_x = 67.0
  let min_y = 0.0
  let max_y = 11.0

  draw_particle_list(
    fb,
    particles,
    emitter_center_x,
    emitter_center_y,
    min_x,
    max_x,
    min_y,
    max_y,
  )
}

fn draw_particle_list(
  fb: ffi.Buffer,
  particles: List(particle_model.Particle),
  center_x: Float,
  center_y: Float,
  min_x: Float,
  max_x: Float,
  min_y: Float,
  max_y: Float,
) -> Nil {
  case particles {
    [] -> Nil
    [p, ..rest] -> {
      draw_single_particle(
        fb,
        p,
        center_x,
        center_y,
        min_x,
        max_x,
        min_y,
        max_y,
      )
      draw_particle_list(
        fb,
        rest,
        center_x,
        center_y,
        min_x,
        max_x,
        min_y,
        max_y,
      )
    }
  }
}

fn draw_single_particle(
  fb: ffi.Buffer,
  p: particle_model.Particle,
  _center_x: Float,
  _center_y: Float,
  min_x: Float,
  max_x: Float,
  min_y: Float,
  max_y: Float,
) -> Nil {
  // Clamp to framebuffer bounds
  let #(clamped_x, clamped_y) =
    particle_model.clamp_to_bounds(p, min_x, max_x, min_y, max_y)

  // Use clamped positions for drawing
  let draw_x = float.truncate(clamped_x)
  let draw_y = float.truncate(clamped_y)

  // Get character and color based on particle state
  let char = particle_model.particle_char(p)
  let hue = particle_model.particle_hue(p)
  let fade = particle_model.fade_factor(p)
  let #(r, g, b, _) = model.hue_to_rgb(hue)

  // Apply fade to color
  let color = #(r *. fade, g *. fade, b *. fade, 1.0)

  buffer.set_cell(fb, draw_x, draw_y, char, color, #(0.0, 0.0, 0.0, 0.0), 0)
}
