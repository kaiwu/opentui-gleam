import gleam/float
import gleam/int
import opentui/buffer
import opentui/examples/common
import opentui/examples/phase4_model
import opentui/examples/phase4_state as state
import opentui/examples/physx_rapier_2d_demo_model as model
import opentui/ffi
import opentui/math3d
import opentui/physics2d.{type Body, Circle, Rect}

const arena_x = 4

const arena_y = 4

const arena_w = 72

const arena_h = 14

pub fn main() -> Nil {
  let system_cell = state.create_generic(model.create())

  common.run_animated_demo(
    "PhysX Rapier 2D Demo",
    "PhysX Rapier 2D Demo",
    fn(key) { handle_key(system_cell, key) },
    fn(dt) {
      let system = state.get_generic(system_cell)
      state.set_generic(system_cell, model.tick(system, dt))
    },
    fn(buf) { draw(buf, system_cell) },
  )
}

fn handle_key(system_cell: state.GenericCell, key: String) -> Nil {
  let system = state.get_generic(system_cell)
  let updated = case key {
    " " -> model.spawn(system)
    "b" -> model.burst(system)
    "a" -> model.toggle_auto(system)
    "c" -> model.clear(system)
    "r" -> model.reset(system)
    "p" -> model.toggle_pause(system)
    _ -> system
  }
  state.set_generic(system_cell, updated)
}

fn draw(buf: ffi.Buffer, system_cell: state.GenericCell) -> Nil {
  let system = state.get_generic(system_cell)

  common.draw_panel(buf, 2, 2, 76, 19, "Rapier 2D Crate Arena")
  draw_arena(buf)
  draw_bodies(buf, model.get_bodies(system), 0)

  buffer.draw_text(
    buf,
    model.format_status(system),
    5,
    19,
    common.fg_color,
    common.panel_bg,
    0,
  )

  buffer.draw_text(
    buf,
    model.format_instructions(),
    3,
    common.term_h - 1,
    common.muted_fg,
    common.status_bg,
    0,
  )
}

fn draw_arena(buf: ffi.Buffer) -> Nil {
  buffer.fill_rect(buf, arena_x + 1, arena_y + 1, arena_w - 2, arena_h - 2, #(
    0.05,
    0.045,
    0.08,
    1.0,
  ))

  common.each_index(arena_w, fn(i) {
    let floor_color = case i > 0 && i < arena_w - 1 {
      True -> common.accent_pink
      False -> common.border_fg
    }
    buffer.set_cell(
      buf,
      arena_x + i,
      arena_y,
      0x2500,
      common.border_fg,
      common.panel_bg,
      0,
    )
    buffer.set_cell(
      buf,
      arena_x + i,
      arena_y + arena_h - 1,
      0x2500,
      floor_color,
      common.panel_bg,
      0,
    )
  })

  common.each_index(arena_h, fn(i) {
    buffer.set_cell(
      buf,
      arena_x,
      arena_y + i,
      0x2502,
      common.border_fg,
      common.panel_bg,
      0,
    )
    buffer.set_cell(
      buf,
      arena_x + arena_w - 1,
      arena_y + i,
      0x2502,
      common.border_fg,
      common.panel_bg,
      0,
    )
  })

  buffer.set_cell(
    buf,
    arena_x,
    arena_y,
    0x250c,
    common.border_fg,
    common.panel_bg,
    0,
  )
  buffer.set_cell(
    buf,
    arena_x + arena_w - 1,
    arena_y,
    0x2510,
    common.border_fg,
    common.panel_bg,
    0,
  )
  buffer.set_cell(
    buf,
    arena_x,
    arena_y + arena_h - 1,
    0x2514,
    common.border_fg,
    common.panel_bg,
    0,
  )
  buffer.set_cell(
    buf,
    arena_x + arena_w - 1,
    arena_y + arena_h - 1,
    0x2518,
    common.border_fg,
    common.panel_bg,
    0,
  )

  buffer.draw_text(
    buf,
    "mixed-shape drop zone",
    arena_x + 2,
    arena_y + 1,
    common.muted_fg,
    #(0.05, 0.045, 0.08, 1.0),
    0,
  )
}

fn draw_bodies(buf: ffi.Buffer, bodies: List(Body), index: Int) -> Nil {
  case bodies {
    [] -> Nil
    [body, ..rest] -> {
      draw_body(buf, body, index)
      draw_bodies(buf, rest, index + 1)
    }
  }
}

fn draw_body(buf: ffi.Buffer, body: Body, index: Int) -> Nil {
  let sx = arena_x + 1 + float.truncate(body.position.x)
  let sy = arena_y + 1 + float.truncate(body.position.y)
  case
    sx > arena_x
    && sx < arena_x + arena_w - 1
    && sy > arena_y
    && sy < arena_y + arena_h - 1
  {
    True -> {
      let hue = int.to_float({ index * 39 } % 360)
      let #(r, g, b, _) = phase4_model.hue_to_rgb(hue)
      let energy = speed(body)
      let glow = case energy >. 5.5 {
        True -> 1.0
        False -> 0.75
      }
      let color = #(r *. glow, g *. glow, b *. glow, 1.0)
      let char = body_char(body)
      buffer.set_cell(buf, sx, sy, char, color, #(0.0, 0.0, 0.0, 0.0), 0)
      draw_echo(buf, sx, sy, body, color)
    }
    False -> Nil
  }
}

fn body_char(body: Body) -> Int {
  case body.shape {
    Rect(width:, height:) ->
      case width >. height {
        True -> 0x25AC
        False ->
          case speed(body) >. 4.0 {
            True -> 0x25A3
            False -> 0x25A0
          }
      }
    Circle(..) ->
      case speed(body) >. 4.5 {
        True -> 0x25C9
        False -> 0x25C7
      }
  }
}

fn draw_echo(
  buf: ffi.Buffer,
  sx: Int,
  sy: Int,
  body: Body,
  color: #(Float, Float, Float, Float),
) -> Nil {
  let dx = velocity_sign(body.velocity.x)
  let dy = velocity_sign(body.velocity.y)
  case dx == 0 && dy == 0 {
    True -> Nil
    False -> {
      let tx = sx - dx
      let ty = sy - dy
      case
        tx > arena_x
        && tx < arena_x + arena_w - 1
        && ty > arena_y
        && ty < arena_y + arena_h - 1
      {
        True ->
          buffer.set_cell(
            buf,
            tx,
            ty,
            0x2571,
            #(color.0 *. 0.45, color.1 *. 0.45, color.2 *. 0.45, 1.0),
            #(0.0, 0.0, 0.0, 0.0),
            0,
          )
        False -> Nil
      }
    }
  }
}

fn velocity_sign(value: Float) -> Int {
  case value >. 0.5 {
    True -> 1
    False ->
      case value <. -0.5 {
        True -> -1
        False -> 0
      }
  }
}

fn speed(body: Body) -> Float {
  let vx = body.velocity.x
  let vy = body.velocity.y
  math3d.sqrt(vx *. vx +. vy *. vy)
}
