import gleam/float
import gleam/int
import gleam/list
import opentui/animation
import opentui/buffer
import opentui/examples/common
import opentui/examples/phase4_model
import opentui/examples/phase4_state as state
import opentui/examples/phase5_model as model
import opentui/ffi
import opentui/framebuffer
import opentui/lighting
import opentui/math3d.{type Vec3, Vec3}

pub fn main() -> Nil {
  let time = state.create_float(0.0)

  common.run_animated_demo(
    "Golden Star Demo",
    "Golden Star Demo",
    fn(_key) { Nil },
    fn(dt) { state.set_float(time, state.get_float(time) +. dt) },
    fn(buf) { draw(buf, time) },
  )
}

fn draw(buf: ffi.Buffer, time: state.FloatCell) -> Nil {
  let t = state.get_float(time)

  // Background pattern via framebuffer
  let assert Ok(bg) = framebuffer.create(76, 20, "star_bg")
  draw_bg_pattern(bg, t)
  framebuffer.draw_onto(buf, 2, 2, bg)
  framebuffer.destroy(bg)

  // Timeline for rotation and scale
  let tl =
    animation.create(5000.0, True)
    |> animation.add_tween("rot", 0.0, animation.Tween(0.0, 6.28, 5000.0, animation.linear))
    |> animation.add_tween("scale", 0.0, animation.Tween(8.0, 14.0, 2500.0, animation.ease_in_out))
  let elapsed = t -. int.to_float(float.truncate(t /. 5000.0)) *. 5000.0
  let tl = animation.tick(tl, elapsed)
  let rot = animation.value(tl, "rot")
  let scale = animation.value(tl, "scale")

  // Star points (5-pointed star as 10 vertices alternating inner/outer)
  let star_verts = star_vertices(5, 1.0, 0.4)
  let light_dir = math3d.vec3_normalize(Vec3(0.5, 0.8, 0.3))

  // Draw star edges
  draw_star(buf, star_verts, rot, scale, 40.0, 11.0, light_dir, t)

  // Title overlay
  let assert Ok(overlay) = framebuffer.create(30, 3, "star_title")
  buffer.fill_rect(overlay, 0, 0, 30, 3, #(0.0, 0.0, 0.0, 0.6))
  buffer.draw_text(overlay, "  Golden Star Showcase  ", 3, 1, #(1.0, 0.85, 0.3, 1.0), #(0.0, 0.0, 0.0, 0.6), 1)
  framebuffer.draw_onto(buf, 25, 2, overlay)
  framebuffer.destroy(overlay)

  buffer.draw_text(buf,
    " rotation + scale + lighting + framebuffer compositing",
    4, common.term_h - 1, common.fg_color, common.status_bg, 0)
}

fn star_vertices(points: Int, outer: Float, inner: Float) -> List(Vec3) {
  build_star(points, outer, inner, 0, points * 2, [])
}

fn build_star(_points: Int, outer: Float, inner: Float, i: Int, total: Int, acc: List(Vec3)) -> List(Vec3) {
  case i >= total {
    True -> reverse(acc, [])
    False -> {
      let angle = math3d.pi() *. 2.0 *. int.to_float(i) /. int.to_float(total) -. math3d.pi() /. 2.0
      let r = case i % 2 == 0 {
            True -> outer
            False -> inner
          }
      let v = Vec3(math3d.cos(angle) *. r, math3d.sin(angle) *. r, 0.0)
      build_star(0, outer, inner, i + 1, total, [v, ..acc])
    }
  }
}

fn draw_star(
  buf: ffi.Buffer,
  verts: List(Vec3),
  rot: Float,
  scale: Float,
  cx: Float,
  cy: Float,
  light_dir: Vec3,
  time: Float,
) -> Nil {
  let projected = list.map(verts, fn(v) {
    let rotated = math3d.rotate_z(v, rot)
    let #(sx, sy) = math3d.project_simple(rotated, scale, cx, cy)
    #(float.truncate(sx), float.truncate(sy), rotated)
  })
  draw_star_edges(buf, projected, light_dir, time, 0)
}

fn draw_star_edges(
  buf: ffi.Buffer,
  verts: List(#(Int, Int, Vec3)),
  light_dir: Vec3,
  time: Float,
  i: Int,
) -> Nil {
  let len = list.length(verts)
  case i >= len {
    True -> Nil
    False -> {
      let j = { i + 1 } % len
      let #(ax, ay, a_pos) = list_at(verts, i)
      let #(bx, by, _) = list_at(verts, j)

      let normal = math3d.vec3_normalize(a_pos)
      let brightness = lighting.diffuse(normal, light_dir) *. 0.6 +. 0.4

      // Golden color with hue shift at edges
      let hue_shift = math3d.sin(time *. 0.002 +. int.to_float(i)) *. 15.0
      let #(r, g, b, _) = phase4_model.hue_to_rgb(45.0 +. hue_shift)

      let points = model.line_points(ax, ay, bx, by)
      let char = model.shade_char(brightness)
      let color = #(r *. brightness, g *. brightness, b *. brightness *. 0.3, 1.0)
      draw_points(buf, points, char, color)

      draw_star_edges(buf, verts, light_dir, time, i + 1)
    }
  }
}

fn draw_points(buf: ffi.Buffer, pts: List(#(Int, Int)), char: Int, color: #(Float, Float, Float, Float)) -> Nil {
  case pts {
    [] -> Nil
    [#(x, y), ..rest] -> {
      case x >= 3 && x < 77 && y >= 3 && y < 21 {
        True -> buffer.set_cell(buf, x, y, char, color, #(0.0, 0.0, 0.0, 0.0), 0)
        False -> Nil
      }
      draw_points(buf, rest, char, color)
    }
  }
}

fn draw_bg_pattern(fb: ffi.Buffer, time: Float) -> Nil {
  draw_bg_rows(fb, time, 0, 76, 20)
}

fn draw_bg_rows(fb: ffi.Buffer, time: Float, y: Int, w: Int, h: Int) -> Nil {
  case y >= h {
    True -> Nil
    False -> {
      draw_bg_cols(fb, time, 0, y, w)
      draw_bg_rows(fb, time, y + 1, w, h)
    }
  }
}

fn draw_bg_cols(fb: ffi.Buffer, time: Float, x: Int, y: Int, w: Int) -> Nil {
  case x >= w {
    True -> Nil
    False -> {
      let hue = int.to_float({ x * 5 + y * 7 } % 360) +. time *. 0.01
      let #(r, g, b, _) = phase4_model.hue_to_rgb(hue)
      buffer.set_cell(fb, x, y, 0xB7, #(r *. 0.08, g *. 0.08, b *. 0.08, 1.0), common.bg_color, 0)
      draw_bg_cols(fb, time, x + 1, y, w)
    }
  }
}

fn list_at(items: List(a), index: Int) -> a {
  case items, index {
    [item, ..], 0 -> item
    [_, ..rest], n -> list_at(rest, n - 1)
    [], _ -> panic as "index out of bounds"
  }
}

fn reverse(items: List(a), acc: List(a)) -> List(a) {
  case items {
    [] -> acc
    [h, ..t] -> reverse(t, [h, ..acc])
  }
}
