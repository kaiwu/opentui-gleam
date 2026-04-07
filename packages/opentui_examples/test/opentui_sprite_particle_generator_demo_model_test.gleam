import gleam/float
import gleam/list
import gleeunit/should
import opentui/examples/sprite_particle_generator_demo_model as model

// ---------------------------------------------------------------------------
// Creation Tests
// ---------------------------------------------------------------------------

pub fn create_default_test() {
  let system = model.create()
  let _ = model.particle_count(system) |> should.equal(0)
  let _ = model.is_auto(system) |> should.equal(False)
  let _ = model.is_emission_active(system) |> should.equal(True)
  model.get_preset_id(system) |> should.equal(model.FountainPreset)
}

pub fn create_with_preset_fountain_test() {
  let system = model.create_with_preset(model.FountainPreset)
  model.get_preset_id(system) |> should.equal(model.FountainPreset)
}

pub fn create_with_preset_sparkle_test() {
  let system = model.create_with_preset(model.SparklePreset)
  model.get_preset_id(system) |> should.equal(model.SparklePreset)
}

// ---------------------------------------------------------------------------
// Tick / Update Tests
// ---------------------------------------------------------------------------

pub fn tick_no_particles_no_auto_test() {
  let system = model.create()
  let system = model.tick(system, 0.5)
  model.particle_count(system) |> should.equal(0)
}

pub fn tick_auto_emission_creates_particles_test() {
  let system = model.create()
  let system = model.toggle_auto(system)
  let system = model.tick(system, 0.5)
  // Should spawn ~3 particles per second, so 0.5s -> ~1-2 particles
  { model.particle_count(system) > 0 } |> should.equal(True)
}

pub fn tick_updates_particle_positions_test() {
  // Create a system with a manually added particle
  let system = model.create()
  let p =
    model.Particle(
      x: 10.0,
      y: 5.0,
      vx: 2.0,
      vy: -3.0,
      age: 0.0,
      max_age: 10.0,
      seed: 0,
    )
  let system = model.System(..system, particles: [p])
  let system = model.tick(system, 1.0)
  let particles = model.get_particles(system)
  let updated = list.first(particles)
  case updated {
    Ok(p) -> {
      // Position should have moved by velocity * dt
      p.x |> should.equal(12.0)
      // Y velocity changes due to gravity: -3.0 + 4.0*1.0 = 1.0, y = 5.0 + 1.0 = 6.0
      p.y |> should.equal(6.0)
    }
    Error(_) -> should.equal(0, 1)
    // fail
  }
}

pub fn tick_prunes_expired_particles_test() {
  let system = model.create()
  let p =
    model.Particle(
      x: 0.0,
      y: 0.0,
      vx: 0.0,
      vy: 0.0,
      age: 4.0,
      max_age: 3.0,
      // already expired
      seed: 0,
    )
  let system = model.System(..system, particles: [p])
  let system = model.tick(system, 0.1)
  model.particle_count(system) |> should.equal(0)
}

pub fn tick_accumulates_age_test() {
  let system = model.create()
  let p =
    model.Particle(
      x: 0.0,
      y: 0.0,
      vx: 0.0,
      vy: 0.0,
      age: 1.0,
      max_age: 5.0,
      seed: 0,
    )
  let system = model.System(..system, particles: [p])
  let system = model.tick(system, 0.5)
  let particles = model.get_particles(system)
  case list.first(particles) {
    Ok(p) -> p.age |> should.equal(1.5)
    Error(_) -> should.equal(0, 1)
    // fail
  }
}

// ---------------------------------------------------------------------------
// Control Tests
// ---------------------------------------------------------------------------

pub fn burst_creates_particles_test() {
  let system = model.create()
  let system = model.burst(system)
  // Fountain preset: 12 particles
  model.particle_count(system) |> should.equal(12)
}

pub fn burst_sparkle_more_particles_test() {
  let system = model.create_with_preset(model.SparklePreset)
  let system = model.burst(system)
  // Sparkle preset: 20 particles
  model.particle_count(system) |> should.equal(20)
}

pub fn stop_emission_disables_spawning_test() {
  let system = model.create()
  let system = model.toggle_auto(system)
  let system = model.stop_emission(system)
  let system = model.tick(system, 1.0)
  // No new particles should spawn even with auto on
  model.particle_count(system) |> should.equal(0)
}

pub fn clear_removes_particles_test() {
  let system = model.burst(model.create())
  let count_before = model.particle_count(system)
  { count_before > 0 } |> should.equal(True)
  let system = model.clear(system)
  model.particle_count(system) |> should.equal(0)
}

pub fn toggle_auto_flips_state_test() {
  let system = model.create()
  let _ = model.is_auto(system) |> should.equal(False)
  let system = model.toggle_auto(system)
  model.is_auto(system) |> should.equal(True)
}

pub fn toggle_auto_can_turn_off_test() {
  let system = model.toggle_auto(model.create())
  let system = model.toggle_auto(system)
  model.is_auto(system) |> should.equal(False)
}

pub fn next_preset_cycles_test() {
  let system = model.create()
  let _ = model.get_preset_id(system) |> should.equal(model.FountainPreset)
  let system = model.next_preset(system)
  model.get_preset_id(system) |> should.equal(model.SparklePreset)
}

pub fn next_preset_cycles_back_test() {
  let system = model.create_with_preset(model.SparklePreset)
  let system = model.next_preset(system)
  model.get_preset_id(system) |> should.equal(model.FountainPreset)
}

pub fn reset_clears_and_returns_default_test() {
  let system =
    model.burst(
      model.toggle_auto(model.create_with_preset(model.SparklePreset)),
    )
  let system = model.reset(system)
  let _ = model.particle_count(system) |> should.equal(0)
  let _ = model.is_auto(system) |> should.equal(False)
  let _ = model.is_emission_active(system) |> should.equal(True)
  model.get_preset_id(system) |> should.equal(model.FountainPreset)
}

// ---------------------------------------------------------------------------
// Preset Tests
// ---------------------------------------------------------------------------

pub fn preset_from_id_fountain_test() {
  let preset = model.preset_from_id(model.FountainPreset)
  // Just verify it's a Fountain variant
  case preset {
    model.Fountain(_, _, _) -> should.equal(True, True)
    model.Sparkle(_, _) -> should.equal(True, False)
  }
}

pub fn preset_from_id_sparkle_test() {
  let preset = model.preset_from_id(model.SparklePreset)
  case preset {
    model.Fountain(_, _, _) -> should.equal(True, False)
    model.Sparkle(_, _) -> should.equal(True, True)
  }
}

pub fn preset_name_fountain_test() {
  model.preset_name(model.FountainPreset) |> should.equal("Fountain")
}

pub fn preset_name_sparkle_test() {
  model.preset_name(model.SparklePreset) |> should.equal("Sparkle")
}

pub fn next_preset_id_test() {
  let _ =
    model.next_preset_id(model.FountainPreset)
    |> should.equal(model.SparklePreset)
  model.next_preset_id(model.SparklePreset)
  |> should.equal(model.FountainPreset)
}

// ---------------------------------------------------------------------------
// Status Formatting Tests
// ---------------------------------------------------------------------------

pub fn format_status_idle_fountain_test() {
  let system = model.create()
  let status = model.format_status(system)
  status |> should.equal("Fountain  idle/on  particles: 0")
}

pub fn format_status_auto_sparkle_test() {
  let system = model.toggle_auto(model.create_with_preset(model.SparklePreset))
  let status = model.format_status(system)
  status |> should.equal("Sparkle  auto/on  particles: 0")
}

pub fn format_status_stopped_emission_test() {
  let system = model.stop_emission(model.create())
  let status = model.format_status(system)
  status |> should.equal("Fountain  idle/off  particles: 0")
}

pub fn format_status_with_particles_test() {
  let system = model.burst(model.create())
  let status = model.format_status(system)
  status |> should.equal("Fountain  idle/on  particles: 12")
}

pub fn format_instructions_test() {
  model.format_instructions()
  |> should.equal("b: burst  a: auto  s: stop  x: clear  m: mode  r: reset")
}

// ---------------------------------------------------------------------------
// Particle Lifecycle Tests
// ---------------------------------------------------------------------------

pub fn life_fraction_new_particle_test() {
  let p =
    model.Particle(
      x: 0.0,
      y: 0.0,
      vx: 0.0,
      vy: 0.0,
      age: 0.0,
      max_age: 3.0,
      seed: 0,
    )
  model.life_fraction(p) |> should.equal(0.0)
}

pub fn life_fraction_half_life_test() {
  let p =
    model.Particle(
      x: 0.0,
      y: 0.0,
      vx: 0.0,
      vy: 0.0,
      age: 1.5,
      max_age: 3.0,
      seed: 0,
    )
  assert_near(model.life_fraction(p), 0.5)
}

pub fn life_fraction_near_end_test() {
  let p =
    model.Particle(
      x: 0.0,
      y: 0.0,
      vx: 0.0,
      vy: 0.0,
      age: 2.7,
      max_age: 3.0,
      seed: 0,
    )
  assert_near(model.life_fraction(p), 0.9)
}

pub fn fade_factor_full_at_start_test() {
  let p =
    model.Particle(
      x: 0.0,
      y: 0.0,
      vx: 0.0,
      vy: 0.0,
      age: 0.0,
      max_age: 3.0,
      seed: 0,
    )
  model.fade_factor(p) |> should.equal(1.0)
}

pub fn fade_factor_still_full_at_half_test() {
  let p =
    model.Particle(
      x: 0.0,
      y: 0.0,
      vx: 0.0,
      vy: 0.0,
      age: 1.5,
      max_age: 3.0,
      seed: 0,
    )
  model.fade_factor(p) |> should.equal(1.0)
}

pub fn fade_factor_fading_at_end_test() {
  let p =
    model.Particle(
      x: 0.0,
      y: 0.0,
      vx: 0.0,
      vy: 0.0,
      age: 2.5,
      max_age: 3.0,
      seed: 0,
    )
  // age/max_age = 0.83, which is > 0.67, so fading
  // fade = 1.0 - (0.83 - 0.67) / 0.33 = 1.0 - 0.48 = 0.52
  assert_near(model.fade_factor(p), 0.52)
}

pub fn fade_factor_zero_at_expired_test() {
  let p =
    model.Particle(
      x: 0.0,
      y: 0.0,
      vx: 0.0,
      vy: 0.0,
      age: 3.0,
      max_age: 3.0,
      seed: 0,
    )
  // age/max_age = 1.0, > 0.67
  // fade = 1.0 - (1.0 - 0.67) / 0.33 = 1.0 - 1.0 = 0.0
  assert_near(model.fade_factor(p), 0.0)
}

pub fn particle_char_varies_by_seed_test() {
  let p0 =
    model.Particle(
      x: 0.0,
      y: 0.0,
      vx: 0.0,
      vy: 0.0,
      age: 0.0,
      max_age: 1.0,
      seed: 0,
    )
  let p1 =
    model.Particle(
      x: 0.0,
      y: 0.0,
      vx: 0.0,
      vy: 0.0,
      age: 0.0,
      max_age: 1.0,
      seed: 1,
    )
  // Different seeds give different chars (modulo 4)
  let c0 = model.particle_char(p0)
  let c1 = model.particle_char(p1)
  // 0 % 4 = 0 -> bullet, 1 % 4 = 1 -> large circle
  c0 |> should.equal(0x2022)
  // bullet
  c1 |> should.equal(0x25CF)
  // large circle
}

pub fn particle_hue_varies_by_seed_test() {
  let p0 =
    model.Particle(
      x: 0.0,
      y: 0.0,
      vx: 0.0,
      vy: 0.0,
      age: 0.0,
      max_age: 1.0,
      seed: 0,
    )
  let p1 =
    model.Particle(
      x: 0.0,
      y: 0.0,
      vx: 0.0,
      vy: 0.0,
      age: 0.0,
      max_age: 1.0,
      seed: 1,
    )
  let h0 = model.particle_hue(p0)
  let h1 = model.particle_hue(p1)
  // Different seeds give different hues (modulo 360)
  let diff = float.absolute_value(h0 -. h1)
  { diff >. 0.0 } |> should.equal(True)
}

pub fn clamp_to_bounds_inside_test() {
  let p =
    model.Particle(
      x: 5.0,
      y: 5.0,
      vx: 0.0,
      vy: 0.0,
      age: 0.0,
      max_age: 1.0,
      seed: 0,
    )
  let #(x, y) = model.clamp_to_bounds(p, 0.0, 10.0, 0.0, 10.0)
  let _ = x |> should.equal(5.0)
  y |> should.equal(5.0)
}

pub fn clamp_to_bounds_outside_test() {
  let p =
    model.Particle(
      x: 15.0,
      y: -3.0,
      vx: 0.0,
      vy: 0.0,
      age: 0.0,
      max_age: 1.0,
      seed: 0,
    )
  let #(x, y) = model.clamp_to_bounds(p, 0.0, 10.0, 0.0, 10.0)
  let _ = x |> should.equal(10.0)
  y |> should.equal(0.0)
}

// ---------------------------------------------------------------------------
// Helper
// ---------------------------------------------------------------------------

fn assert_near(actual: Float, expected: Float) -> Nil {
  let diff = float.absolute_value(actual -. expected)
  { diff <. 0.05 } |> should.equal(True)
}
