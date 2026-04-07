import gleam/float
import gleam/int
import opentui/buffer
import opentui/examples/common
import opentui/examples/phase4_model
import opentui/examples/phase4_state as state
import opentui/examples/physx_planck_2d_demo_model as model
import opentui/ffi
import opentui/math3d
import opentui/physics2d.{type Body, Circle, Rect}

const sandbox_x = 4

const sandbox_y = 4

const sandbox_w = 72

const sandbox_h = 14

pub fn main() -> Nil {
  let system_cell = state.create_generic(model.create())

  common.run_animated_demo(
    "PhysX Planck 2D Demo",
    "PhysX Planck 2D Demo",
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

  common.draw_panel(buf, 2, 2, 76, 19, "Planck 2D Physics Sandbox")
  draw_sandbox(buf)
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

fn draw_sandbox(buf: ffi.Buffer) -> Nil {
  buffer.fill_rect(
    buf,
    sandbox_x + 1,
    sandbox_y + 1,
    sandbox_w - 2,
    sandbox_h - 2,
    #(0.04, 0.05, 0.09, 1.0),
  )

  common.each_index(sandbox_w, fn(i) {
    let ground_color = case i > 0 && i < sandbox_w - 1 {
      True -> common.accent_orange
      False -> common.border_fg
    }
    buffer.set_cell(
      buf,
      sandbox_x + i,
      sandbox_y,
      0x2500,
      common.border_fg,
      common.panel_bg,
      0,
    )
    buffer.set_cell(
      buf,
      sandbox_x + i,
      sandbox_y + sandbox_h - 1,
      0x2500,
      ground_color,
      common.panel_bg,
      0,
    )
  })

  common.each_index(sandbox_h, fn(i) {
    buffer.set_cell(
      buf,
      sandbox_x,
      sandbox_y + i,
      0x2502,
      common.border_fg,
      common.panel_bg,
      0,
    )
    buffer.set_cell(
      buf,
      sandbox_x + sandbox_w - 1,
      sandbox_y + i,
      0x2502,
      common.border_fg,
      common.panel_bg,
      0,
    )
  })

  buffer.set_cell(
    buf,
    sandbox_x,
    sandbox_y,
    0x250c,
    common.border_fg,
    common.panel_bg,
    0,
  )
  buffer.set_cell(
    buf,
    sandbox_x + sandbox_w - 1,
    sandbox_y,
    0x2510,
    common.border_fg,
    common.panel_bg,
    0,
  )
  buffer.set_cell(
    buf,
    sandbox_x,
    sandbox_y + sandbox_h - 1,
    0x2514,
    common.border_fg,
    common.panel_bg,
    0,
  )
  buffer.set_cell(
    buf,
    sandbox_x + sandbox_w - 1,
    sandbox_y + sandbox_h - 1,
    0x2518,
    common.border_fg,
    common.panel_bg,
    0,
  )

  buffer.draw_text(
    buf,
    "spawn zone",
    sandbox_x + 2,
    sandbox_y + 1,
    common.muted_fg,
    #(0.04, 0.05, 0.09, 1.0),
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
  let sx = sandbox_x + 1 + float.truncate(body.position.x)
  let sy = sandbox_y + 1 + float.truncate(body.position.y)
  case
    sx > sandbox_x
    && sx < sandbox_x + sandbox_w - 1
    && sy > sandbox_y
    && sy < sandbox_y + sandbox_h - 1
  {
    True -> {
      let hue = int.to_float({ index * 47 } % 360)
      let #(r, g, b, _) = phase4_model.hue_to_rgb(hue)
      let color = #(r, g, b, 1.0)
      let char = body_char(body)
      buffer.set_cell(buf, sx, sy, char, color, #(0.0, 0.0, 0.0, 0.0), 0)
      draw_velocity_trail(buf, body, sx, sy, color)
    }
    False -> Nil
  }
}

fn body_char(body: Body) -> Int {
  case body.shape {
    Rect(..) -> {
      let phase = float.truncate(body.angle *. 2.0) % 4
      case phase {
        0 -> 0x25A0
        1 -> 0x25A3
        2 -> 0x25A1
        _ -> 0x25A6
      }
    }
    Circle(..) ->
      case speed(body) >. 5.0 {
        True -> 0x25CF
        False -> 0x25CB
      }
  }
}

fn draw_velocity_trail(
  buf: ffi.Buffer,
  body: Body,
  sx: Int,
  sy: Int,
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
        tx > sandbox_x
        && tx < sandbox_x + sandbox_w - 1
        && ty > sandbox_y
        && ty < sandbox_y + sandbox_h - 1
      {
        True ->
          buffer.set_cell(
            buf,
            tx,
            ty,
            0x00B7,
            #(color.0 *. 0.55, color.1 *. 0.55, color.2 *. 0.55, 1.0),
            #(0.0, 0.0, 0.0, 0.0),
            0,
          )
        False -> Nil
      }
    }
  }
}

fn velocity_sign(value: Float) -> Int {
  case value >. 0.4 {
    True -> 1
    False ->
      case value <. -0.4 {
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
