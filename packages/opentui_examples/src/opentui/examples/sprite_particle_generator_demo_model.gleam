import gleam/float
import gleam/int
import gleam/list

// Particle generator system model (pure, demo-local).
//
// This model handles:
// - particle lifecycle (spawn, update, prune)
// - emission modes (auto, burst, stopped)
// - presets with distinct behavior patterns
// - physics-like motion with gravity
//
// The model is pure and testable without requiring runtime/FFI.
// ---------------------------------------------------------------------------
// Particle Data
// ---------------------------------------------------------------------------

// A single particle with position, velocity, and lifetime.
pub type Particle {
  Particle(
    // X position (float for smooth motion)
    x: Float,
    // Y position (float for smooth motion)
    y: Float,
    // X velocity (cells per second)
    vx: Float,
    // Y velocity (cells per second)
    vy: Float,
    // Age in seconds
    age: Float,
    // Maximum lifetime in seconds
    max_age: Float,
    // Seed for deterministic variation (color, char)
    seed: Int,
  )
}

// ---------------------------------------------------------------------------
// Presets
// ---------------------------------------------------------------------------

/// Emission preset defining spawn behavior.
pub type Preset {
  /// Fountain: particles rise upward then fall with gravity
  Fountain(
    /// Base upward velocity (cells/sec)
    base_vy: Float,
    /// Spread in X direction (cells/sec)
    spread_vx: Float,
    /// Lifetime range (min, max)
    lifetime_range: #(Float, Float),
  )
  /// Sparkle: particles burst outward from center with random directions
  Sparkle(
    /// Base speed (cells/sec)
    base_speed: Float,
    /// Lifetime range (min, max)
    lifetime_range: #(Float, Float),
  )
}

/// Preset identifiers for display.
pub type PresetId {
  FountainPreset
  SparklePreset
}

/// Get the preset definition from an ID.
pub fn preset_from_id(id: PresetId) -> Preset {
  case id {
    FountainPreset ->
      Fountain(base_vy: 8.0, spread_vx: 3.0, lifetime_range: #(2.0, 4.0))
    SparklePreset -> Sparkle(base_speed: 6.0, lifetime_range: #(1.0, 2.0))
  }
}

/// Get preset name for display.
pub fn preset_name(id: PresetId) -> String {
  case id {
    FountainPreset -> "Fountain"
    SparklePreset -> "Sparkle"
  }
}

/// Cycle to the next preset.
pub fn next_preset_id(id: PresetId) -> PresetId {
  case id {
    FountainPreset -> SparklePreset
    SparklePreset -> FountainPreset
  }
}

// ---------------------------------------------------------------------------
// Particle System State
// ---------------------------------------------------------------------------

/// Particle generator system state.
pub type System {
  System(
    /// Active particles
    particles: List(Particle),
    /// Current preset ID
    preset_id: PresetId,
    /// Auto-emission enabled (continuous spawning)
    auto_emission: Bool,
    /// Emission active (can be stopped separately from auto)
    emission_active: Bool,
    /// Emitter spawn counter for seed generation
    spawn_counter: Int,
    /// Gravity (cells/sec^2, positive = downward)
    gravity: Float,
  )
}

/// Create a new particle system with default settings.
pub fn create() -> System {
  System(
    particles: [],
    preset_id: FountainPreset,
    auto_emission: False,
    emission_active: True,
    spawn_counter: 0,
    gravity: 4.0,
  )
}

/// Create a system with a specific preset.
pub fn create_with_preset(id: PresetId) -> System {
  System(..create(), preset_id: id)
}

// ---------------------------------------------------------------------------
// Tick / Update
// ---------------------------------------------------------------------------

/// Tick the system forward by dt seconds.
/// Updates particle positions, applies gravity, prunes expired particles,
/// and spawns new particles if auto-emission is active.
pub fn tick(system: System, dt: Float) -> System {
  // Update existing particles
  let updated =
    list.map(system.particles, fn(p) { update_particle(p, dt, system.gravity) })

  // Prune expired particles
  let alive = prune_expired(updated)

  // Spawn new particles if auto-emission is active
  let new_particles = case system.auto_emission && system.emission_active {
    True -> spawn_batch(system, dt)
    False -> []
  }

  System(
    ..system,
    particles: list.append(alive, new_particles),
    spawn_counter: system.spawn_counter + list.length(new_particles),
  )
}

/// Update a single particle's position and age.
fn update_particle(p: Particle, dt: Float, gravity: Float) -> Particle {
  let new_vy = p.vy +. gravity *. dt
  Particle(
    x: p.x +. p.vx *. dt,
    y: p.y +. new_vy *. dt,
    vx: p.vx,
    vy: new_vy,
    age: p.age +. dt,
    max_age: p.max_age,
    seed: p.seed,
  )
}

/// Remove particles whose age exceeds max_age.
fn prune_expired(particles: List(Particle)) -> List(Particle) {
  list.filter(particles, fn(p) { p.age <. p.max_age })
}

// ---------------------------------------------------------------------------
// Spawn
// ---------------------------------------------------------------------------

/// Spawn a batch of particles based on preset and emission rate.
fn spawn_batch(system: System, dt: Float) -> List(Particle) {
  let preset = preset_from_id(system.preset_id)
  // Emit ~3 particles per second when auto is on
  let rate = 3.0
  let spawn_count = float.truncate(rate *. dt)
  let actual_count = case spawn_count < 1 {
    True -> 1
    False -> spawn_count
  }
  spawn_particles(system, preset, actual_count)
}

/// Spawn multiple particles using the preset.
fn spawn_particles(system: System, preset: Preset, count: Int) -> List(Particle) {
  spawn_particles_loop(system, preset, count, 0, [])
}

fn spawn_particles_loop(
  system: System,
  preset: Preset,
  count: Int,
  i: Int,
  acc: List(Particle),
) -> List(Particle) {
  case i >= count {
    True -> acc
    False -> {
      let seed = system.spawn_counter + i
      let p = spawn_one(preset, seed)
      spawn_particles_loop(system, preset, count, i + 1, [p, ..acc])
    }
  }
}

/// Spawn a single particle based on preset.
fn spawn_one(preset: Preset, seed: Int) -> Particle {
  case preset {
    Fountain(base_vy, spread_vx, lifetime_range) -> {
      // Spawn at emitter center (0, 0), upward velocity with X spread
      let vx = spread_vx *. seeded_float(seed, 0)
      let vy = float.negate(base_vy) +. seeded_float(seed, 1) *. 0.5
      let max_age =
        lifetime_range.0
        +. seeded_float(seed, 2)
        *. { lifetime_range.1 -. lifetime_range.0 }
      Particle(
        x: 0.0,
        y: 0.0,
        vx: vx,
        vy: vy,
        age: 0.0,
        max_age: max_age,
        seed: seed,
      )
    }
    Sparkle(base_speed, lifetime_range) -> {
      // Spawn at emitter center, burst outward in random direction
      // Use a simple angle approximation based on seed
      let angle_idx = { seed * 7 } % 8
      let #(vx_base, vy_base) = sparkle_direction(angle_idx)
      let speed = base_speed *. { 0.6 +. seeded_float(seed, 1) *. 0.4 }
      let vx = vx_base *. speed
      let vy = vy_base *. speed
      let max_age =
        lifetime_range.0
        +. seeded_float(seed, 2)
        *. { lifetime_range.1 -. lifetime_range.0 }
      Particle(
        x: 0.0,
        y: 0.0,
        vx: vx,
        vy: vy,
        age: 0.0,
        max_age: max_age,
        seed: seed,
      )
    }
  }
}

/// Generate a pseudo-random float 0-1 from a seed and offset.
fn seeded_float(seed: Int, offset: Int) -> Float {
  // Simple deterministic pseudo-random using multiplication and modulo
  let val = { seed * 17 + offset * 31 + 7 } % 1000
  int.to_float(val) /. 1000.0
}

/// Get a sparkle direction vector from an index (8 directions).
fn sparkle_direction(idx: Int) -> #(Float, Float) {
  case idx {
    0 -> #(0.0, -1.0)
    // up
    1 -> #(1.0, -1.0)
    // up-right
    2 -> #(1.0, 0.0)
    // right
    3 -> #(1.0, 1.0)
    // down-right
    4 -> #(0.0, 1.0)
    // down
    5 -> #(-1.0, 1.0)
    // down-left
    6 -> #(-1.0, 0.0)
    // left
    _ -> #(-1.0, -1.0)
    // up-left
  }
}

// ---------------------------------------------------------------------------
// Controls
// ---------------------------------------------------------------------------

/// Burst: spawn a large batch of particles immediately.
pub fn burst(system: System) -> System {
  let preset = preset_from_id(system.preset_id)
  // Spawn 12-20 particles based on preset
  let count = case system.preset_id {
    FountainPreset -> 12
    SparklePreset -> 20
  }
  let new_particles = spawn_particles(system, preset, count)
  System(
    ..system,
    particles: list.append(system.particles, new_particles),
    spawn_counter: system.spawn_counter + count,
  )
}

/// Stop emission: pause spawning new particles.
pub fn stop_emission(system: System) -> System {
  System(..system, emission_active: False)
}

/// Clear: remove all particles immediately.
pub fn clear(system: System) -> System {
  System(..system, particles: [])
}

/// Toggle auto-emission mode.
pub fn toggle_auto(system: System) -> System {
  System(..system, auto_emission: !system.auto_emission)
}

/// Switch to the next preset.
pub fn next_preset(system: System) -> System {
  System(..system, preset_id: next_preset_id(system.preset_id))
}

/// Reset system to initial state (clear particles, reset preset, auto off).
pub fn reset(_system: System) -> System {
  System(
    particles: [],
    preset_id: FountainPreset,
    auto_emission: False,
    emission_active: True,
    spawn_counter: 0,
    gravity: 4.0,
  )
}

// ---------------------------------------------------------------------------
// Query
// ---------------------------------------------------------------------------

/// Get current particle count.
pub fn particle_count(system: System) -> Int {
  list.length(system.particles)
}

/// Get all particles (for rendering).
pub fn get_particles(system: System) -> List(Particle) {
  system.particles
}

/// Get current preset ID.
pub fn get_preset_id(system: System) -> PresetId {
  system.preset_id
}

/// Check if auto-emission is enabled.
pub fn is_auto(system: System) -> Bool {
  system.auto_emission
}

/// Check if emission is active.
pub fn is_emission_active(system: System) -> Bool {
  system.emission_active
}

// ---------------------------------------------------------------------------
// Status Formatting
// ---------------------------------------------------------------------------

/// Format system state for display.
pub fn format_status(system: System) -> String {
  let preset = preset_name(system.preset_id)
  let mode = case system.auto_emission {
    True -> "auto"
    False -> "idle"
  }
  let emission = case system.emission_active {
    True -> "on"
    False -> "off"
  }
  let count = particle_count(system)
  preset
  <> "  "
  <> mode
  <> "/"
  <> emission
  <> "  particles: "
  <> int.to_string(count)
}

/// Format instructions for display.
pub fn format_instructions() -> String {
  "b: burst  a: auto  s: stop  x: clear  m: mode  r: reset"
}

// ---------------------------------------------------------------------------
// Rendering Helpers
// ---------------------------------------------------------------------------

/// Compute life fraction (0.0 = newborn, 1.0 = expired).
pub fn life_fraction(p: Particle) -> Float {
  p.age /. p.max_age
}

/// Get a fade factor based on life fraction (1.0 = full, 0.0 = faded).
pub fn fade_factor(p: Particle) -> Float {
  let frac = life_fraction(p)
  // Fade out in the last third of life
  case frac >. 0.67 {
    True -> 1.0 -. { frac -. 0.67 } /. 0.33
    False -> 1.0
  }
}

/// Get a color hue based on particle seed and life.
pub fn particle_hue(p: Particle) -> Float {
  let base = int.to_float({ p.seed * 37 } % 360)
  // Shift hue over lifetime
  base +. life_fraction(p) *. 180.0
}

/// Get a character codepoint based on particle seed and life.
pub fn particle_char(p: Particle) -> Int {
  let phase = { p.seed + float.truncate(p.age *. 5.0) } % 4
  case phase {
    0 -> 0x2022
    // bullet
    1 -> 0x25CF
    // large circle
    2 -> 0x2726
    // sparkle
    _ -> 0x00B7
    // middle dot
  }
}

/// Clamp a position to emitter bounds (for rendering).
pub fn clamp_to_bounds(
  p: Particle,
  min_x: Float,
  max_x: Float,
  min_y: Float,
  max_y: Float,
) -> #(Float, Float) {
  let x = float.min(float.max(p.x, min_x), max_x)
  let y = float.min(float.max(p.y, min_y), max_y)
  #(x, y)
}
