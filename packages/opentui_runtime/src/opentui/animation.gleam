import gleam/float
import gleam/int
import gleam/list

pub type Tween {
  Tween(
    from: Float,
    to: Float,
    duration: Float,
    easing: fn(Float) -> Float,
  )
}

pub type Timeline {
  Timeline(
    duration: Float,
    elapsed: Float,
    looping: Bool,
    tweens: List(#(String, Float, Tween)),
  )
}

/// Create a new timeline.
pub fn create(duration: Float, looping: Bool) -> Timeline {
  Timeline(duration: duration, elapsed: 0.0, looping: looping, tweens: [])
}

/// Add a named tween to a timeline.
pub fn add_tween(
  tl: Timeline,
  name: String,
  start_offset: Float,
  tween: Tween,
) -> Timeline {
  Timeline(..tl, tweens: [#(name, start_offset, tween), ..tl.tweens])
}

/// Advance the timeline by delta milliseconds.
pub fn tick(tl: Timeline, dt: Float) -> Timeline {
  let new_elapsed = tl.elapsed +. dt
  case tl.looping {
    True -> {
      case tl.duration >. 0.0 {
        True -> Timeline(..tl, elapsed: fmod(new_elapsed, tl.duration))
        False -> Timeline(..tl, elapsed: 0.0)
      }
    }
    False -> Timeline(..tl, elapsed: float.min(new_elapsed, tl.duration))
  }
}

/// Get the overall progress (0.0 to 1.0).
pub fn progress(tl: Timeline) -> Float {
  case tl.duration >. 0.0 {
    True -> float.min(tl.elapsed /. tl.duration, 1.0)
    False -> 1.0
  }
}

/// Check if the timeline is complete (non-looping only).
pub fn is_done(tl: Timeline) -> Bool {
  case tl.looping {
    True -> False
    False -> tl.elapsed >=. tl.duration
  }
}

/// Get the interpolated value of a named tween.
pub fn value(tl: Timeline, name: String) -> Float {
  case find_tween(tl.tweens, name) {
    Error(_) -> 0.0
    Ok(#(_, offset, tween)) -> {
      let local_time = tl.elapsed -. offset
      case local_time <. 0.0 {
        True -> tween.from
        False -> {
          let t = case tween.duration >. 0.0 {
            True -> float.min(local_time /. tween.duration, 1.0)
            False -> 1.0
          }
          let eased = tween.easing(t)
          lerp(tween.from, tween.to, eased)
        }
      }
    }
  }
}

/// Linear easing (identity).
pub fn linear(t: Float) -> Float {
  t
}

/// Smooth ease in-out (cubic).
pub fn ease_in_out(t: Float) -> Float {
  case t <. 0.5 {
    True -> 4.0 *. t *. t *. t
    False -> {
      let p = 2.0 *. t -. 2.0
      0.5 *. p *. p *. p +. 1.0
    }
  }
}

/// Ease out bounce.
pub fn ease_out_bounce(t: Float) -> Float {
  case t <. 1.0 /. 2.75 {
    True -> 7.5625 *. t *. t
    False ->
      case t <. 2.0 /. 2.75 {
        True -> {
          let t1 = t -. 1.5 /. 2.75
          7.5625 *. t1 *. t1 +. 0.75
        }
        False ->
          case t <. 2.5 /. 2.75 {
            True -> {
              let t2 = t -. 2.25 /. 2.75
              7.5625 *. t2 *. t2 +. 0.9375
            }
            False -> {
              let t3 = t -. 2.625 /. 2.75
              7.5625 *. t3 *. t3 +. 0.984375
            }
          }
      }
  }
}

/// Linear interpolation.
pub fn lerp(from: Float, to: Float, t: Float) -> Float {
  from +. { to -. from } *. t
}

fn find_tween(
  tweens: List(#(String, Float, Tween)),
  name: String,
) -> Result(#(String, Float, Tween), Nil) {
  list.find(tweens, fn(entry) {
    let #(n, _, _) = entry
    n == name
  })
}

fn fmod(a: Float, b: Float) -> Float {
  let div = float.truncate(a /. b)
  a -. int.to_float(div) *. b
}
