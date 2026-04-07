import gleam/float
import gleam/int

/// Sprite animation playback state (pure model for demo-local use).
/// 
/// This model handles the timing logic for sprite sheet animation:
/// - frame progression based on elapsed time
/// - pause/resume control
/// - speed adjustment
/// - single-step frame advancement
/// 
pub type Animator {
  Animator(
    /// Whether animation is currently playing
    running: Bool,
    /// Accumulated time in milliseconds (only increments when running)
    elapsed_ms: Float,
    /// Base frame duration in milliseconds (200ms default = 5 FPS)
    frame_duration_ms: Float,
    /// Number of frames in the sprite sheet
    frame_count: Int,
  )
}

/// Create a new animator with default 200ms frame duration.
pub fn create(frame_count: Int) -> Animator {
  Animator(
    running: True,
    elapsed_ms: 0.0,
    frame_duration_ms: 200.0,
    frame_count: frame_count,
  )
}

/// Create a new animator with custom frame duration.
pub fn create_with_duration(
  frame_count: Int,
  frame_duration_ms: Float,
) -> Animator {
  Animator(
    running: True,
    elapsed_ms: 0.0,
    frame_duration_ms: clamp_duration(frame_duration_ms),
    frame_count: frame_count,
  )
}

/// Clamp frame duration to reasonable bounds (50ms–2000ms).
pub fn clamp_duration(d: Float) -> Float {
  float.min(float.max(d, 50.0), 2000.0)
}

/// Tick the animator forward by dt milliseconds.
/// Only advances elapsed time if running is True.
pub fn tick(animator: Animator, dt_ms: Float) -> Animator {
  case animator.running {
    True -> Animator(..animator, elapsed_ms: animator.elapsed_ms +. dt_ms)
    False -> animator
  }
}

/// Pause the animation.
pub fn pause(animator: Animator) -> Animator {
  Animator(..animator, running: False)
}

/// Resume the animation.
pub fn resume(animator: Animator) -> Animator {
  Animator(..animator, running: True)
}

/// Toggle pause/resume state.
pub fn toggle_running(animator: Animator) -> Animator {
  Animator(..animator, running: !animator.running)
}

/// Calculate the current frame index (0-based).
pub fn current_frame(animator: Animator) -> Int {
  let cycle_length =
    animator.frame_duration_ms *. int.to_float(animator.frame_count)
  let normalized_time = animator.elapsed_ms /. cycle_length
  let frame =
    float.truncate(normalized_time *. int.to_float(animator.frame_count))
  frame % animator.frame_count
}

/// Step forward one frame (useful when paused).
pub fn step_frame(animator: Animator) -> Animator {
  // Advance elapsed time by one frame duration
  Animator(
    ..animator,
    elapsed_ms: animator.elapsed_ms +. animator.frame_duration_ms,
  )
}

/// Reset animator to initial state (frame 0, running).
pub fn reset(animator: Animator) -> Animator {
  Animator(
    running: True,
    elapsed_ms: 0.0,
    frame_duration_ms: animator.frame_duration_ms,
    frame_count: animator.frame_count,
  )
}

/// Increase speed (decrease frame duration) by 50ms.
pub fn increase_speed(animator: Animator) -> Animator {
  Animator(
    ..animator,
    frame_duration_ms: clamp_duration(animator.frame_duration_ms -. 50.0),
  )
}

/// Decrease speed (increase frame duration) by 50ms.
pub fn decrease_speed(animator: Animator) -> Animator {
  Animator(
    ..animator,
    frame_duration_ms: clamp_duration(animator.frame_duration_ms +. 50.0),
  )
}

/// Get frame duration in milliseconds.
pub fn get_frame_duration_ms(animator: Animator) -> Float {
  animator.frame_duration_ms
}

/// Get current elapsed time in milliseconds.
pub fn get_elapsed_ms(animator: Animator) -> Float {
  animator.elapsed_ms
}

/// Check if animator is currently running.
pub fn is_running(animator: Animator) -> Bool {
  animator.running
}

/// Format speed as FPS (frames per second).
pub fn fps(animator: Animator) -> Float {
  1000.0 /. animator.frame_duration_ms
}

/// Format current state for display.
pub fn format_status(animator: Animator) -> String {
  let state = case animator.running {
    True -> "running"
    False -> "paused"
  }
  let frame = current_frame(animator)
  let fps_val = float.truncate(fps(animator))
  "frame: "
  <> int.to_string(frame)
  <> "/"
  <> int.to_string(animator.frame_count)
  <> "  "
  <> state
  <> "  "
  <> int.to_string(fps_val)
  <> " FPS"
}
