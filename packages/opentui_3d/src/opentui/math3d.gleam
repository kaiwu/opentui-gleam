import gleam/float
import gleam/int

// ---------------------------------------------------------------------------
// Trig FFI
// ---------------------------------------------------------------------------

@external(javascript, "./math_ffi.js", "sin")
pub fn sin(x: Float) -> Float

@external(javascript, "./math_ffi.js", "cos")
pub fn cos(x: Float) -> Float

@external(javascript, "./math_ffi.js", "sqrt")
pub fn sqrt(x: Float) -> Float

@external(javascript, "./math_ffi.js", "atan2")
pub fn atan2(y: Float, x: Float) -> Float

@external(javascript, "./math_ffi.js", "pow")
pub fn pow(base: Float, exp: Float) -> Float

@external(javascript, "./math_ffi.js", "pi")
pub fn pi() -> Float

// ---------------------------------------------------------------------------
// Vec3
// ---------------------------------------------------------------------------

pub type Vec3 {
  Vec3(x: Float, y: Float, z: Float)
}

pub fn vec3_add(a: Vec3, b: Vec3) -> Vec3 {
  Vec3(a.x +. b.x, a.y +. b.y, a.z +. b.z)
}

pub fn vec3_sub(a: Vec3, b: Vec3) -> Vec3 {
  Vec3(a.x -. b.x, a.y -. b.y, a.z -. b.z)
}

pub fn vec3_scale(v: Vec3, s: Float) -> Vec3 {
  Vec3(v.x *. s, v.y *. s, v.z *. s)
}

pub fn vec3_dot(a: Vec3, b: Vec3) -> Float {
  a.x *. b.x +. a.y *. b.y +. a.z *. b.z
}

pub fn vec3_cross(a: Vec3, b: Vec3) -> Vec3 {
  Vec3(
    a.y *. b.z -. a.z *. b.y,
    a.z *. b.x -. a.x *. b.z,
    a.x *. b.y -. a.y *. b.x,
  )
}

pub fn vec3_length(v: Vec3) -> Float {
  sqrt(v.x *. v.x +. v.y *. v.y +. v.z *. v.z)
}

pub fn vec3_normalize(v: Vec3) -> Vec3 {
  let len = vec3_length(v)
  case len >. 0.0001 {
    True -> Vec3(v.x /. len, v.y /. len, v.z /. len)
    False -> Vec3(0.0, 0.0, 0.0)
  }
}

pub fn vec3_negate(v: Vec3) -> Vec3 {
  Vec3(0.0 -. v.x, 0.0 -. v.y, 0.0 -. v.z)
}

// ---------------------------------------------------------------------------
// Rotations (angle in radians)
// ---------------------------------------------------------------------------

pub fn degrees_to_radians(deg: Float) -> Float {
  deg *. pi() /. 180.0
}

pub fn rotate_x(v: Vec3, angle: Float) -> Vec3 {
  let c = cos(angle)
  let s = sin(angle)
  Vec3(v.x, v.y *. c -. v.z *. s, v.y *. s +. v.z *. c)
}

pub fn rotate_y(v: Vec3, angle: Float) -> Vec3 {
  let c = cos(angle)
  let s = sin(angle)
  Vec3(v.x *. c +. v.z *. s, v.y, 0.0 -. v.x *. s +. v.z *. c)
}

pub fn rotate_z(v: Vec3, angle: Float) -> Vec3 {
  let c = cos(angle)
  let s = sin(angle)
  Vec3(v.x *. c -. v.y *. s, v.x *. s +. v.y *. c, v.z)
}

/// Apply euler rotation (x, y, z order).
pub fn rotate_euler(v: Vec3, rx: Float, ry: Float, rz: Float) -> Vec3 {
  v |> rotate_x(rx) |> rotate_y(ry) |> rotate_z(rz)
}

// ---------------------------------------------------------------------------
// Projection
// ---------------------------------------------------------------------------

/// Project a 3D point to 2D screen coordinates using perspective projection.
/// Returns #(screen_x, screen_y, depth).
/// camera_pos: where the camera is.
/// camera_target: what the camera looks at.
/// fov: field of view in radians.
pub fn project(
  point: Vec3,
  camera_pos: Vec3,
  camera_target: Vec3,
  fov: Float,
  viewport_w: Int,
  viewport_h: Int,
) -> #(Float, Float, Float) {
  // Camera forward direction
  let forward = vec3_normalize(vec3_sub(camera_target, camera_pos))
  let world_up = Vec3(0.0, 1.0, 0.0)
  let right = vec3_normalize(vec3_cross(forward, world_up))
  let up = vec3_cross(right, forward)

  // Point relative to camera
  let rel = vec3_sub(point, camera_pos)
  let depth = vec3_dot(rel, forward)

  case depth >. 0.001 {
    False -> #(-1000.0, -1000.0, depth)
    True -> {
      let scale = 1.0 /. { depth *. tan_half(fov) }
      let sx = vec3_dot(rel, right) *. scale
      let sy = vec3_dot(rel, up) *. scale

      let hw = int.to_float(viewport_w) /. 2.0
      let hh = int.to_float(viewport_h) /. 2.0

      #(hw +. sx *. hw, hh -. sy *. hh, depth)
    }
  }
}

/// Simpler orthographic-like projection for small viewports.
pub fn project_simple(
  point: Vec3,
  scale: Float,
  cx: Float,
  cy: Float,
) -> #(Float, Float) {
  let depth_factor = 1.0 +. point.z *. 0.1
  let sx = cx +. point.x *. scale /. depth_factor
  let sy = cy -. point.y *. scale /. depth_factor
  #(sx, sy)
}

// ---------------------------------------------------------------------------
// Utilities
// ---------------------------------------------------------------------------

/// Linearly interpolate between two Vec3 values.
pub fn vec3_lerp(a: Vec3, b: Vec3, t: Float) -> Vec3 {
  Vec3(
    a.x +. { b.x -. a.x } *. t,
    a.y +. { b.y -. a.y } *. t,
    a.z +. { b.z -. a.z } *. t,
  )
}

/// Clamp a float to [lo, hi].
pub fn clamp(v: Float, lo: Float, hi: Float) -> Float {
  float.min(float.max(v, lo), hi)
}

fn tan_half(fov: Float) -> Float {
  let half = fov /. 2.0
  sin(half) /. cos(half)
}
