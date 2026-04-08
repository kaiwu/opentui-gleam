import gleam/float
import opentui/math

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

pub type Vec2 {
  Vec2(x: Float, y: Float)
}

pub type Shape {
  Circle(radius: Float)
  Rect(width: Float, height: Float)
}

pub type Body {
  Body(
    position: Vec2,
    velocity: Vec2,
    angle: Float,
    angular_velocity: Float,
    mass: Float,
    restitution: Float,
    shape: Shape,
  )
}

pub type World {
  World(
    bodies: List(Body),
    gravity: Vec2,
    bounds: #(Float, Float, Float, Float),
  )
}

// ---------------------------------------------------------------------------
// World operations
// ---------------------------------------------------------------------------

/// Create a world with given gravity and bounds (min_x, min_y, max_x, max_y).
pub fn create_world(
  gravity: Vec2,
  bounds: #(Float, Float, Float, Float),
) -> World {
  World(bodies: [], gravity: gravity, bounds: bounds)
}

/// Add a body to the world.
pub fn add_body(world: World, body: Body) -> World {
  World(..world, bodies: [body, ..world.bodies])
}

/// Step the physics world by dt seconds.
pub fn step(world: World, dt: Float) -> World {
  let clamped_dt = float.min(dt, 0.05)
  let integrated =
    map_bodies(world.bodies, fn(b) { integrate(b, world.gravity, clamped_dt) })
  let constrained =
    map_bodies(integrated, fn(b) { constrain(b, world.bounds) })
  let resolved = resolve_collisions(constrained)
  World(..world, bodies: resolved)
}

// ---------------------------------------------------------------------------
// Integration
// ---------------------------------------------------------------------------

/// Apply gravity and integrate velocity into position.
pub fn integrate(body: Body, gravity: Vec2, dt: Float) -> Body {
  let new_vx = body.velocity.x +. gravity.x *. dt
  let new_vy = body.velocity.y +. gravity.y *. dt
  let new_px = body.position.x +. new_vx *. dt
  let new_py = body.position.y +. new_vy *. dt
  let new_angle = body.angle +. body.angular_velocity *. dt
  Body(
    ..body,
    position: Vec2(new_px, new_py),
    velocity: Vec2(new_vx, new_vy),
    angle: new_angle,
  )
}

// ---------------------------------------------------------------------------
// Bounds constraint
// ---------------------------------------------------------------------------

/// Bounce body off world bounds.
pub fn constrain(
  body: Body,
  bounds: #(Float, Float, Float, Float),
) -> Body {
  let #(min_x, min_y, max_x, max_y) = bounds
  let r = body_radius(body)

  let #(px, vx) = bounce_axis(body.position.x, body.velocity.x, min_x +. r, max_x -. r, body.restitution)
  let #(py, vy) = bounce_axis(body.position.y, body.velocity.y, min_y +. r, max_y -. r, body.restitution)

  Body(..body, position: Vec2(px, py), velocity: Vec2(vx, vy))
}

fn bounce_axis(
  pos: Float,
  vel: Float,
  lo: Float,
  hi: Float,
  restitution: Float,
) -> #(Float, Float) {
  case pos <. lo {
    True -> #(lo, float.absolute_value(vel) *. restitution)
    False ->
      case pos >. hi {
        True -> #(hi, 0.0 -. float.absolute_value(vel) *. restitution)
        False -> #(pos, vel)
      }
  }
}

// ---------------------------------------------------------------------------
// Collision
// ---------------------------------------------------------------------------

/// Check and resolve circle-circle collision between two bodies.
pub fn collide_circles(a: Body, b: Body) -> #(Body, Body) {
  let ra = body_radius(a)
  let rb = body_radius(b)
  let dx = b.position.x -. a.position.x
  let dy = b.position.y -. a.position.y
  let dist_sq = dx *. dx +. dy *. dy
  let min_dist = ra +. rb

  case dist_sq <. min_dist *. min_dist && dist_sq >. 0.0001 {
    False -> #(a, b)
    True -> {
      let dist = math.sqrt(dist_sq)
      let nx = dx /. dist
      let ny = dy /. dist

      // Separate bodies
      let overlap = min_dist -. dist
      let half_overlap = overlap /. 2.0
      let a_pos =
        Vec2(a.position.x -. nx *. half_overlap, a.position.y -. ny *. half_overlap)
      let b_pos =
        Vec2(b.position.x +. nx *. half_overlap, b.position.y +. ny *. half_overlap)

      // Elastic collision response
      let rel_vx = a.velocity.x -. b.velocity.x
      let rel_vy = a.velocity.y -. b.velocity.y
      let rel_v_dot_n = rel_vx *. nx +. rel_vy *. ny

      // Only resolve if bodies are moving toward each other
      case rel_v_dot_n >. 0.0 {
        False -> #(a, b)
        True -> {
          let restitution = float.min(a.restitution, b.restitution)
          let total_mass = a.mass +. b.mass
          let impulse = { 1.0 +. restitution } *. rel_v_dot_n /. total_mass

          let a_new = Body(
            ..a,
            position: a_pos,
            velocity: Vec2(
              a.velocity.x -. impulse *. b.mass *. nx,
              a.velocity.y -. impulse *. b.mass *. ny,
            ),
          )
          let b_new = Body(
            ..b,
            position: b_pos,
            velocity: Vec2(
              b.velocity.x +. impulse *. a.mass *. nx,
              b.velocity.y +. impulse *. a.mass *. ny,
            ),
          )
          #(a_new, b_new)
        }
      }
    }
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

fn body_radius(body: Body) -> Float {
  case body.shape {
    Circle(radius:) -> radius
    Rect(width:, height:) -> {
      let half_w = width /. 2.0
      let half_h = height /. 2.0
      math.sqrt(half_w *. half_w +. half_h *. half_h)
    }
  }
}

fn map_bodies(bodies: List(Body), f: fn(Body) -> Body) -> List(Body) {
  case bodies {
    [] -> []
    [b, ..rest] -> [f(b), ..map_bodies(rest, f)]
  }
}

fn resolve_collisions(bodies: List(Body)) -> List(Body) {
  resolve_pairs(bodies, 0, list_length(bodies))
}

fn resolve_pairs(
  bodies: List(Body),
  i: Int,
  len: Int,
) -> List(Body) {
  case i >= len - 1 {
    True -> bodies
    False -> {
      let updated = resolve_one_against_rest(bodies, i, i + 1, len)
      resolve_pairs(updated, i + 1, len)
    }
  }
}

fn resolve_one_against_rest(
  bodies: List(Body),
  i: Int,
  j: Int,
  len: Int,
) -> List(Body) {
  case j >= len {
    True -> bodies
    False -> {
      let a = list_at(bodies, i)
      let b = list_at(bodies, j)
      let #(a_new, b_new) = collide_circles(a, b)
      let updated = list_set(list_set(bodies, i, a_new), j, b_new)
      resolve_one_against_rest(updated, i, j + 1, len)
    }
  }
}

fn list_length(items: List(a)) -> Int {
  list_length_loop(items, 0)
}

fn list_length_loop(items: List(a), acc: Int) -> Int {
  case items {
    [] -> acc
    [_, ..rest] -> list_length_loop(rest, acc + 1)
  }
}

fn list_at(items: List(a), index: Int) -> a {
  case items, index {
    [item, ..], 0 -> item
    [_, ..rest], n -> list_at(rest, n - 1)
    [], _ -> panic as "list_at: index out of bounds"
  }
}

fn list_set(items: List(a), index: Int, value: a) -> List(a) {
  case items, index {
    [_, ..rest], 0 -> [value, ..rest]
    [item, ..rest], n -> [item, ..list_set(rest, n - 1, value)]
    [], _ -> []
  }
}
