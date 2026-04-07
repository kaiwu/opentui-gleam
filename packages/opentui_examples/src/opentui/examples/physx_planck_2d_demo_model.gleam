import gleam/int
import opentui/physics2d.{type Body, type World, Body, Circle, Rect, Vec2}

pub type System {
  System(
    world: World,
    auto_spawn: Bool,
    paused: Bool,
    spawn_timer_ms: Float,
    spawn_counter: Int,
    max_bodies: Int,
  )
}

const min_x = 0.0

const min_y = 0.0

const max_x = 67.0

const max_y = 11.0

const spawn_interval_ms = 800.0

const default_max_bodies = 24

pub fn create() -> System {
  System(
    world: seed_world(base_world(), 0, 3),
    auto_spawn: True,
    paused: False,
    spawn_timer_ms: 0.0,
    spawn_counter: 3,
    max_bodies: default_max_bodies,
  )
}

pub fn tick(system: System, dt_ms: Float) -> System {
  case system.paused {
    True -> system
    False -> {
      let stepped = physics2d.step(system.world, dt_ms /. 1000.0)
      let updated = System(..system, world: stepped)
      case updated.auto_spawn {
        True -> apply_auto_spawn(updated, updated.spawn_timer_ms +. dt_ms)
        False -> System(..updated, spawn_timer_ms: 0.0)
      }
    }
  }
}

pub fn spawn(system: System) -> System {
  spawn_many(system, 1)
}

pub fn burst(system: System) -> System {
  spawn_many(system, 4)
}

pub fn toggle_auto(system: System) -> System {
  System(..system, auto_spawn: !system.auto_spawn, spawn_timer_ms: 0.0)
}

pub fn toggle_pause(system: System) -> System {
  System(..system, paused: !system.paused)
}

pub fn clear(system: System) -> System {
  System(..system, world: base_world(), spawn_timer_ms: 0.0)
}

pub fn reset(_system: System) -> System {
  create()
}

pub fn body_count(system: System) -> Int {
  count_bodies(system.world.bodies)
}

pub fn get_bodies(system: System) -> List(Body) {
  system.world.bodies
}

pub fn is_auto(system: System) -> Bool {
  system.auto_spawn
}

pub fn is_paused(system: System) -> Bool {
  system.paused
}

pub fn max_bodies(system: System) -> Int {
  system.max_bodies
}

pub fn format_status(system: System) -> String {
  let auto_text = case system.auto_spawn {
    True -> "on"
    False -> "off"
  }
  let state = case system.paused {
    True -> "paused"
    False -> "running"
  }
  let cap = case body_count(system) >= system.max_bodies {
    True -> "  max reached"
    False -> ""
  }
  "bodies: "
  <> int.to_string(body_count(system))
  <> "/"
  <> int.to_string(system.max_bodies)
  <> "  auto: "
  <> auto_text
  <> "  "
  <> state
  <> cap
}

pub fn format_instructions() -> String {
  "Space: spawn  b: burst  a: auto  c: clear  r: reset  p: pause"
}

fn apply_auto_spawn(system: System, timer_ms: Float) -> System {
  case timer_ms <. spawn_interval_ms {
    True -> System(..system, spawn_timer_ms: timer_ms)
    False -> {
      let spawned = spawn(system)
      case spawned.spawn_counter == system.spawn_counter {
        True -> System(..spawned, spawn_timer_ms: 0.0)
        False ->
          apply_auto_spawn(
            System(..spawned, spawn_timer_ms: 0.0),
            timer_ms -. spawn_interval_ms,
          )
      }
    }
  }
}

fn spawn_many(system: System, requested: Int) -> System {
  let room = system.max_bodies - body_count(system)
  let actual = clamp_int(requested, 0, room)
  case actual <= 0 {
    True -> system
    False -> {
      let world = seed_world(system.world, system.spawn_counter, actual)
      System(
        ..system,
        world: world,
        spawn_counter: system.spawn_counter + actual,
        spawn_timer_ms: 0.0,
      )
    }
  }
}

fn seed_world(world: World, start_seed: Int, count: Int) -> World {
  case count <= 0 {
    True -> world
    False ->
      seed_world(
        physics2d.add_body(world, make_body(start_seed)),
        start_seed + 1,
        count - 1,
      )
  }
}

fn make_body(seed: Int) -> Body {
  let x = 6.0 +. int.to_float({ seed * 13 } % 56)
  let y = 1.0 +. int.to_float(seed % 3)
  let vx = seeded_range(seed, 0, -2.2, 2.2)
  let vy = seeded_range(seed, 1, -1.0, 1.2)
  let angle = seeded_range(seed, 2, 0.0, 6.0)
  let angular_velocity = seeded_range(seed, 3, -3.0, 3.0)
  let restitution = seeded_range(seed, 4, 0.45, 0.8)
  let mass = seeded_range(seed, 5, 0.8, 1.6)
  case seed % 4 == 0 {
    True ->
      Body(
        position: Vec2(x, y),
        velocity: Vec2(vx, vy),
        angle: angle,
        angular_velocity: angular_velocity,
        mass: mass,
        restitution: restitution,
        shape: Circle(0.75),
      )
    False ->
      Body(
        position: Vec2(x, y),
        velocity: Vec2(vx, vy),
        angle: angle,
        angular_velocity: angular_velocity,
        mass: mass,
        restitution: restitution,
        shape: Rect(1.4, 1.0),
      )
  }
}

fn seeded_range(seed: Int, salt: Int, min: Float, max: Float) -> Float {
  let raw = { seed * 73 + salt * 37 + 19 } % 1000
  let unit = int.to_float(raw) /. 1000.0
  min +. unit *. { max -. min }
}

fn clamp_int(value: Int, low: Int, high: Int) -> Int {
  case value < low {
    True -> low
    False ->
      case value > high {
        True -> high
        False -> value
      }
  }
}

fn base_world() -> World {
  physics2d.create_world(Vec2(0.0, 9.8), #(min_x, min_y, max_x, max_y))
}

fn count_bodies(bodies: List(Body)) -> Int {
  case bodies {
    [] -> 0
    [_, ..rest] -> 1 + count_bodies(rest)
  }
}
