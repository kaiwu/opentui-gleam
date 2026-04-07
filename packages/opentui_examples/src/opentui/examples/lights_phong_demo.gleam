import gleam/float
import gleam/int
import opentui/buffer
import opentui/examples/common
import opentui/examples/phase4_state as state
import opentui/examples/phase5_model as model
import opentui/ffi
import opentui/lighting
import opentui/math3d.{Vec3}

pub fn main() -> Nil {
  let time = state.create_float(0.0)

  common.run_animated_demo(
    "Lights Phong Demo",
    "Lights Phong Demo",
    fn(_key) { Nil },
    fn(dt) { state.set_float(time, state.get_float(time) +. dt) },
    fn(buf) { draw(buf, time) },
  )
}

fn draw(buf: ffi.Buffer, time: state.FloatCell) -> Nil {
  let t = state.get_float(time) *. 0.001

  common.draw_panel(buf, 2, 2, 76, 19, "Phong-Lit Sphere — Pure Math Shading")

  // Rotating light direction
  let light_angle = t *. 0.8
  let light_dir =
    math3d.vec3_normalize(Vec3(
      math3d.cos(light_angle),
      0.5,
      math3d.sin(light_angle),
    ))

  let lights = [
    lighting.AmbientLight(#(0.15, 0.15, 0.2), 1.0),
    lighting.DirectionalLight(
      math3d.vec3_negate(light_dir),
      #(1.0, 0.95, 0.8),
      1.0,
    ),
  ]

  // Generate sphere points and render
  let sphere = model.sphere_points(1.0, 12, 24)
  let view_pos = Vec3(0.0, 0.0, 5.0)

  draw_sphere_points(buf, sphere, lights, view_pos, 40.0, 11.0, 8.0)

  // Light position indicator
  let lx = 40 + float.truncate(math3d.cos(light_angle) *. 15.0)
  let ly = 11 - float.truncate(math3d.sin(light_angle) *. 5.0)
  case lx >= 3 && lx < 77 && ly >= 3 && ly < 20 {
    True ->
      buffer.set_cell(
        buf,
        lx,
        ly,
        0x2600,
        #(1.0, 0.9, 0.3, 1.0),
        #(0.0, 0.0, 0.0, 0.0),
        0,
      )
    False -> Nil
  }

  buffer.draw_text(
    buf,
    "Ambient + Directional light  |  Phong shininess=32",
    6,
    19,
    common.muted_fg,
    common.panel_bg,
    0,
  )
}

fn draw_sphere_points(
  buf: ffi.Buffer,
  points: List(#(Vec3, Vec3)),
  lights: List(lighting.Light),
  view_pos: Vec3,
  cx: Float,
  cy: Float,
  scale: Float,
) -> Nil {
  case points {
    [] -> Nil
    [#(pos, normal), ..rest] -> {
      let #(sx, sy) = math3d.project_simple(pos, scale, cx, cy)
      let ix = float.truncate(sx)
      let iy = float.truncate(sy)

      case ix >= 3 && ix < 77 && iy >= 3 && iy < 20 {
        True -> {
          let #(r, g, b) =
            lighting.illuminate(lights, pos, normal, view_pos, 32.0)
          let brightness = { r +. g +. b } /. 3.0
          let char = model.shade_char(brightness)
          buffer.set_cell(
            buf,
            ix,
            iy,
            char,
            #(r, g, b, 1.0),
            #(0.0, 0.0, 0.0, 0.0),
            0,
          )
        }
        False -> Nil
      }

      draw_sphere_points(buf, rest, lights, view_pos, cx, cy, scale)
    }
  }
}
