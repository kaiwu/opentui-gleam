import gleam/float
import gleam/int
import opentui/buffer
import opentui/examples/common
import opentui/examples/phase4_model
import opentui/examples/phase4_state as state
import opentui/ffi
import opentui/physics2d.{type Body, type World, Body, Circle, Rect, Vec2}

pub type WorldHolder

@external(javascript, "./phase5_physics_state.js", "createWorldHolder")
fn create_world_holder_js() -> WorldHolder

@external(javascript, "./phase5_physics_state.js", "getWorld")
fn get_world(holder: WorldHolder) -> World

@external(javascript, "./phase5_physics_state.js", "setWorld")
fn set_world(holder: WorldHolder, world: World) -> Nil

pub fn main() -> Nil {
  let time = state.create_float(0.0)
  let world_holder = create_world_holder_js()
  let world =
    physics2d.create_world(Vec2(0.0, 5.0), #(0.0, 0.0, 68.0, 14.0))
    |> physics2d.add_body(make_circle(8.0, 1.0, 5.0, 0.0, 0.9))
    |> physics2d.add_body(make_circle(20.0, 3.0, -3.0, 1.0, 0.9))
    |> physics2d.add_body(make_rect(35.0, 0.0, 2.0, 2.0, 0.9))
    |> physics2d.add_body(make_circle(50.0, 2.0, -4.0, -1.0, 0.9))
    |> physics2d.add_body(make_rect(60.0, 5.0, -1.0, 3.0, 0.9))
    |> physics2d.add_body(make_circle(15.0, 6.0, 6.0, -2.0, 0.9))
    |> physics2d.add_body(make_rect(45.0, 1.0, -2.0, 4.0, 0.9))
    |> physics2d.add_body(make_circle(30.0, 8.0, 1.0, -3.0, 0.9))
  set_world(world_holder, world)

  common.run_animated_demo(
    "PhysX Rapier 2D Demo",
    "PhysX Rapier 2D Demo",
    fn(_key) { Nil },
    fn(dt) {
      state.set_float(time, state.get_float(time) +. dt)
      let w = get_world(world_holder)
      set_world(world_holder, physics2d.step(w, dt /. 1000.0))
    },
    fn(buf) { draw(buf, time, world_holder) },
  )
}

fn draw(buf: ffi.Buffer, time: state.FloatCell, wh: WorldHolder) -> Nil {
  let t = state.get_float(time)
  let world = get_world(wh)

  common.draw_panel(buf, 2, 2, 76, 19, "Rapier 2D Physics — Mixed Shapes")

  buffer.draw_text(buf, repeat("─", 72), 4, 19, common.border_fg, common.panel_bg, 0)

  draw_bodies(buf, world.bodies, 0)

  buffer.draw_text(
    buf,
    " bodies: " <> int.to_string(body_count(world.bodies))
      <> "  gravity: 5.0  restitution: 0.9  t="
      <> int.to_string(float.truncate(t)) <> "ms",
    4, common.term_h - 1, common.fg_color, common.status_bg, 0,
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
          let hue = int.to_float({ i * 45 } % 360)
          let #(r, g, b, _) = phase4_model.hue_to_rgb(hue)
          let color = #(r, g, b, 1.0)
          case body.shape {
            Circle(..) ->
              buffer.set_cell(buf, sx, sy, 0x25CF, color, #(0.0, 0.0, 0.0, 0.0), 0)
            Rect(..) ->
              buffer.set_cell(buf, sx, sy, 0x25A0, color, #(0.0, 0.0, 0.0, 0.0), 0)
          }
        }
        False -> Nil
      }
      draw_bodies(buf, rest, i + 1)
    }
  }
}

fn make_circle(x: Float, y: Float, vx: Float, vy: Float, rest: Float) -> Body {
  Body(Vec2(x, y), Vec2(vx, vy), 0.0, 0.0, 1.0, rest, Circle(0.8))
}

fn make_rect(x: Float, y: Float, vx: Float, vy: Float, rest: Float) -> Body {
  Body(Vec2(x, y), Vec2(vx, vy), 0.0, 0.0, 1.5, rest, Rect(1.5, 1.0))
}

fn body_count(bs: List(Body)) -> Int {
  case bs {
    [] -> 0
    [_, ..r] -> 1 + body_count(r)
  }
}

fn repeat(s: String, n: Int) -> String {
  case n <= 0 {
    True -> ""
    False -> s <> repeat(s, n - 1)
  }
}
