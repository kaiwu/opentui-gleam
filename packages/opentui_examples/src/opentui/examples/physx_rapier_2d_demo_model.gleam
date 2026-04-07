import gleam/int
import opentui/physics2d.{type Body, type World, Body, Circle, Rect, Vec2}
import opentui/timeline

pub type System {
  System(
    world: World,
    auto_spawn: Bool,
    paused: Bool,
    spawn_interval: timeline.Interval,
    spawn_counter: Int,
    max_bodies: Int,
  )
}

const min_x = 0.0

const min_y = 0.0

const max_x = 67.0

const max_y = 11.0

const default_max_bodies = 28

pub fn create() -> System {
  System(
    world: seed_world(base_world(), 0, 6),
    auto_spawn: True,
    paused: False,
    spawn_interval: timeline.every(800.0),
    spawn_counter: 6,
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
        True -> apply_auto_spawn(updated, dt_ms)
        False ->
          System(
            ..updated,
            spawn_interval: timeline.reset(updated.spawn_interval),
          )
      }
    }
  }
}

pub fn spawn(system: System) -> System {
  spawn_many(system, 1)
}

pub fn burst(system: System) -> System {
  spawn_many(system, 6)
}

pub fn toggle_auto(system: System) -> System {
  System(
    ..system,
    auto_spawn: !system.auto_spawn,
    spawn_interval: timeline.reset(system.spawn_interval),
  )
}

pub fn toggle_pause(system: System) -> System {
  System(..system, paused: !system.paused)
}

pub fn clear(system: System) -> System {
  System(
    ..system,
    world: base_world(),
    spawn_interval: timeline.reset(system.spawn_interval),
  )
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

pub fn format_status(system: System) -> String {
  let auto_text = case system.auto_spawn {
    True -> "on"
    False -> "off"
  }
  let state_text = case system.paused {
    True -> "paused"
    False -> "running"
  }
  let cap = case body_count(system) >= system.max_bodies {
    True -> "  packed"
    False -> ""
  }
  "crates: "
  <> int.to_string(body_count(system))
  <> "/"
  <> int.to_string(system.max_bodies)
  <> "  auto: "
  <> auto_text
  <> "  "
  <> state_text
  <> "  bounce: high"
  <> cap
}

pub fn format_instructions() -> String {
  "Space: crate  b: burst  a: auto  c: clear  r: reset  p: pause"
}

fn apply_auto_spawn(system: System, dt_ms: Float) -> System {
  let timeline.TickResult(interval, firings) =
    timeline.tick(system.spawn_interval, dt_ms)
  spawn_firings(System(..system, spawn_interval: interval), firings)
}

fn spawn_firings(system: System, firings: Int) -> System {
  case firings <= 0 {
    True -> system
    False -> spawn_firings(spawn(system), firings - 1)
  }
}

fn spawn_many(system: System, requested: Int) -> System {
  let room = system.max_bodies - body_count(system)
  let actual = clamp_int(requested, 0, room)
  case actual <= 0 {
    True -> system
    False ->
      System(
        ..system,
        world: seed_world(system.world, system.spawn_counter, actual),
        spawn_counter: system.spawn_counter + actual,
        spawn_interval: timeline.reset(system.spawn_interval),
      )
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
  let x = 5.0 +. int.to_float({ seed * 11 } % 58)
  let y = 1.0 +. int.to_float(seed % 4)
  let vx = seeded_range(seed, 0, -3.8, 3.8)
  let vy = seeded_range(seed, 1, -1.5, 2.8)
  let angle = seeded_range(seed, 2, 0.0, 6.0)
  let angular_velocity = seeded_range(seed, 3, -5.0, 5.0)
  let restitution = seeded_range(seed, 4, 0.82, 0.96)
  let mass = seeded_range(seed, 5, 1.0, 2.2)
  case seed % 3 {
    0 ->
      Body(
        position: Vec2(x, y),
        velocity: Vec2(vx, vy),
        angle: angle,
        angular_velocity: angular_velocity,
        mass: mass,
        restitution: restitution,
        shape: Rect(1.6, 1.2),
      )
    1 ->
      Body(
        position: Vec2(x, y),
        velocity: Vec2(vx *. 0.8, vy),
        angle: angle,
        angular_velocity: angular_velocity,
        mass: mass +. 0.3,
        restitution: restitution,
        shape: Rect(1.1, 1.7),
      )
    _ ->
      Body(
        position: Vec2(x, y),
        velocity: Vec2(vx, vy),
        angle: angle,
        angular_velocity: angular_velocity,
        mass: mass,
        restitution: restitution,
        shape: Circle(0.75),
      )
  }
}

fn seeded_range(seed: Int, salt: Int, min: Float, max: Float) -> Float {
  let raw = { seed * 61 + salt * 41 + 23 } % 1000
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
  physics2d.create_world(Vec2(0.0, 5.0), #(min_x, min_y, max_x, max_y))
}

fn count_bodies(bodies: List(Body)) -> Int {
  case bodies {
    [] -> 0
    [_, ..rest] -> 1 + count_bodies(rest)
  }
}
