import gleam/float
import opentui/math3d.{type Vec3}

// ---------------------------------------------------------------------------
// Light types
// ---------------------------------------------------------------------------

pub type Light {
  DirectionalLight(
    direction: Vec3,
    color: #(Float, Float, Float),
    intensity: Float,
  )
  PointLight(
    position: Vec3,
    color: #(Float, Float, Float),
    intensity: Float,
    range: Float,
  )
  AmbientLight(color: #(Float, Float, Float), intensity: Float)
}

// ---------------------------------------------------------------------------
// Phong shading
// ---------------------------------------------------------------------------

/// Compute Phong shading intensity for a single directional light.
/// normal and light_dir should be normalized.
/// Returns a value >= 0.0 (can exceed 1.0 with specular).
pub fn phong(
  normal: Vec3,
  light_dir: Vec3,
  view_dir: Vec3,
  shininess: Float,
) -> Float {
  // Diffuse: max(0, N · L)
  let n_dot_l = math3d.vec3_dot(normal, light_dir)
  let diffuse = float.max(n_dot_l, 0.0)

  // Specular: (R · V)^shininess where R = 2(N·L)N - L
  let specular = case n_dot_l >. 0.0 {
    False -> 0.0
    True -> {
      let reflect =
        math3d.vec3_sub(
          math3d.vec3_scale(normal, 2.0 *. n_dot_l),
          light_dir,
        )
      let r_dot_v = float.max(math3d.vec3_dot(reflect, view_dir), 0.0)
      math3d.pow(r_dot_v, shininess)
    }
  }

  diffuse +. specular
}

/// Compute diffuse-only shading (simpler, no specular).
pub fn diffuse(normal: Vec3, light_dir: Vec3) -> Float {
  float.max(math3d.vec3_dot(normal, light_dir), 0.0)
}

// ---------------------------------------------------------------------------
// Multi-light illumination
// ---------------------------------------------------------------------------

/// Compute total illumination from a list of lights at a surface point.
/// Returns (r, g, b) color contribution.
pub fn illuminate(
  lights: List(Light),
  position: Vec3,
  normal: Vec3,
  view_pos: Vec3,
  shininess: Float,
) -> #(Float, Float, Float) {
  let view_dir = math3d.vec3_normalize(math3d.vec3_sub(view_pos, position))
  illuminate_loop(lights, position, normal, view_dir, shininess, 0.0, 0.0, 0.0)
}

fn illuminate_loop(
  lights: List(Light),
  position: Vec3,
  normal: Vec3,
  view_dir: Vec3,
  shininess: Float,
  r: Float,
  g: Float,
  b: Float,
) -> #(Float, Float, Float) {
  case lights {
    [] -> #(
      float.min(r, 1.0),
      float.min(g, 1.0),
      float.min(b, 1.0),
    )
    [light, ..rest] -> {
      let #(lr, lg, lb) = light_contribution(
        light,
        position,
        normal,
        view_dir,
        shininess,
      )
      illuminate_loop(
        rest,
        position,
        normal,
        view_dir,
        shininess,
        r +. lr,
        g +. lg,
        b +. lb,
      )
    }
  }
}

fn light_contribution(
  light: Light,
  position: Vec3,
  normal: Vec3,
  view_dir: Vec3,
  shininess: Float,
) -> #(Float, Float, Float) {
  case light {
    AmbientLight(color:, intensity:) -> #(
      color.0 *. intensity,
      color.1 *. intensity,
      color.2 *. intensity,
    )

    DirectionalLight(direction:, color:, intensity:) -> {
      let light_dir = math3d.vec3_normalize(math3d.vec3_negate(direction))
      let i = phong(normal, light_dir, view_dir, shininess) *. intensity
      #(color.0 *. i, color.1 *. i, color.2 *. i)
    }

    PointLight(position: light_pos, color:, intensity:, range:) -> {
      let to_light = math3d.vec3_sub(light_pos, position)
      let dist = math3d.vec3_length(to_light)
      case dist >. range {
        True -> #(0.0, 0.0, 0.0)
        False -> {
          let light_dir = math3d.vec3_normalize(to_light)
          let attenuation = 1.0 -. dist /. range
          let i =
            phong(normal, light_dir, view_dir, shininess)
            *. intensity
            *. attenuation
          #(color.0 *. i, color.1 *. i, color.2 *. i)
        }
      }
    }
  }
}
