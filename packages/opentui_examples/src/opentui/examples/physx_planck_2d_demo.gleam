import gleam/float
import gleam/int
import opentui/buffer
import opentui/examples/common
import opentui/examples/phase4_model
import opentui/examples/phase4_state as state
import opentui/ffi
import opentui/math3d
import opentui/physics2d.{type Body, type World, Body, Circle, Vec2}

pub fn main() -> Nil {
  // Store world state as individual float cells for positions
  // We'll store the full world in a JS cell via a trick: serialize to floats
  // Actually, simpler: just recreate world each frame from stored body positions
  let time = state.create_float(0.0)

  // Use a mutable world holder
  let world_holder = create_world_holder()

  common.run_animated_demo(
    "PhysX Planck 2D Demo",
    "PhysX Planck 2D Demo",
    fn(_key) { Nil },
    fn(dt) {
      state.set_float(time, state.get_float(time) +. dt)
      let w = get_world(world_holder)
      let stepped = physics2d.step(w, dt /. 1000.0)
      set_world(world_holder, stepped)
    },
    fn(buf) { draw(buf, time, world_holder) },
  )
}

fn draw(buf: ffi.Buffer, time: state.FloatCell, world_holder: WorldHolder) -> Nil {
  let t = state.get_float(time)
  let world = get_world(world_holder)

  common.draw_panel(buf, 2, 2, 76, 19, "Planck 2D Physics — High Gravity")

  // Draw bounds
  buffer.draw_text(
    buf,
    repeat_char("─", 72),
    4,
    19,
    common.border_fg,
    common.panel_bg,
    0,
  )

  // Draw bodies
  draw_bodies(buf, world.bodies, 0)

  buffer.draw_text(
    buf,
    " bodies: "
      <> int.to_string(count_bodies(world.bodies))
      <> "  gravity: 9.8  restitution: 0.6  t="
      <> int.to_string(float.truncate(t))
      <> "ms",
    4,
    common.term_h - 1,
    common.fg_color,
    common.status_bg,
    0,
  )
}

fn draw_bodies(buf: ffi.Buffer, bodies: List(Body), i: Int) -> Nil {
  case bodies {
    [] -> Nil
    [body, ..rest] -> {
      let sx = float.truncate(body.position.x) + 4
      let sy = float.truncate(body.position.y) + 4

      case sx >= 4 && sx < 76 && sy >= 4 && sy < 20 {
        True -> {
          let hue = int.to_float({ i * 51 } % 360)
          let #(r, g, b, _) = phase4_model.hue_to_rgb(hue)
          let speed =
            math3d.sqrt(
              body.velocity.x *. body.velocity.x
              +. body.velocity.y *. body.velocity.y,
            )
          let char = case speed >. 5.0 {
            True -> 0x25CF   // ●
            False -> 0x25CB  // ○
          }
          buffer.set_cell(buf, sx, sy, char, #(r, g, b, 1.0), #(0.0, 0.0, 0.0, 0.0), 0)
        }
        False -> Nil
      }
      draw_bodies(buf, rest, i + 1)
    }
  }
}

fn count_bodies(bodies: List(Body)) -> Int {
  case bodies {
    [] -> 0
    [_, ..rest] -> 1 + count_bodies(rest)
  }
}

fn repeat_char(s: String, n: Int) -> String {
  case n <= 0 {
    True -> ""
    False -> s <> repeat_char(s, n - 1)
  }
}

// --- World holder (mutable cell for World via JS FFI) ---

pub type WorldHolder

@external(javascript, "./phase5_physics_state.js", "createWorldHolder")
fn create_world_holder_js() -> WorldHolder

@external(javascript, "./phase5_physics_state.js", "getWorld")
fn get_world(holder: WorldHolder) -> World

@external(javascript, "./phase5_physics_state.js", "setWorld")
fn set_world(holder: WorldHolder, world: World) -> Nil

fn create_world_holder() -> WorldHolder {
  let holder = create_world_holder_js()
  let world = physics2d.create_world(Vec2(0.0, 9.8), #(0.0, 0.0, 68.0, 14.0))
  let world =
    world
    |> physics2d.add_body(make_circle(10.0, 2.0, 3.0, 1.0, 0.6))
    |> physics2d.add_body(make_circle(25.0, 1.0, -2.0, 2.0, 0.6))
    |> physics2d.add_body(make_circle(40.0, 3.0, 1.5, -1.0, 0.6))
    |> physics2d.add_body(make_circle(55.0, 0.0, -1.0, 3.0, 0.6))
    |> physics2d.add_body(make_circle(15.0, 5.0, 4.0, 0.5, 0.6))
    |> physics2d.add_body(make_circle(35.0, 4.0, -3.0, -2.0, 0.6))
  set_world(holder, world)
  holder
}

fn make_circle(
  x: Float,
  y: Float,
  vx: Float,
  vy: Float,
  restitution: Float,
) -> Body {
  Body(
    position: Vec2(x, y),
    velocity: Vec2(vx, vy),
    angle: 0.0,
    angular_velocity: 0.0,
    mass: 1.0,
    restitution: restitution,
    shape: Circle(0.8),
  )
}
