import gleam/float
import gleam/int
import opentui/frame_playback

/// Sprite animation playback state (pure model for demo-local use).
/// 
/// This model handles the timing logic for sprite sheet animation:
/// - frame progression based on elapsed time
/// - pause/resume control
/// - speed adjustment
/// - single-step frame advancement
/// 
pub type Animator {
  Animator(playback: frame_playback.Playback)
}

/// Create a new animator with default 200ms frame duration.
pub fn create(frame_count: Int) -> Animator {
  Animator(frame_playback.create(frame_count, 200.0))
}

/// Create a new animator with custom frame duration.
pub fn create_with_duration(
  frame_count: Int,
  frame_duration_ms: Float,
) -> Animator {
  Animator(frame_playback.create(frame_count, frame_duration_ms))
}

/// Clamp frame duration to reasonable bounds (50ms–2000ms).
pub fn clamp_duration(d: Float) -> Float {
  frame_playback.clamp_duration(d)
}

/// Tick the animator forward by dt milliseconds.
/// Only advances elapsed time if running is True.
pub fn tick(animator: Animator, dt_ms: Float) -> Animator {
  case animator {
    Animator(playback) -> Animator(frame_playback.tick(playback, dt_ms))
  }
}

/// Pause the animation.
pub fn pause(animator: Animator) -> Animator {
  case animator {
    Animator(playback) -> Animator(frame_playback.pause(playback))
  }
}

/// Resume the animation.
pub fn resume(animator: Animator) -> Animator {
  case animator {
    Animator(playback) -> Animator(frame_playback.resume(playback))
  }
}

/// Toggle pause/resume state.
pub fn toggle_running(animator: Animator) -> Animator {
  case animator {
    Animator(playback) -> Animator(frame_playback.toggle_running(playback))
  }
}

/// Calculate the current frame index (0-based).
pub fn current_frame(animator: Animator) -> Int {
  case animator {
    Animator(playback) -> frame_playback.current_frame(playback)
  }
}

/// Step forward one frame (useful when paused).
pub fn step_frame(animator: Animator) -> Animator {
  case animator {
    Animator(playback) -> Animator(frame_playback.step_frame(playback))
  }
}

/// Reset animator to initial state (frame 0, running).
pub fn reset(animator: Animator) -> Animator {
  case animator {
    Animator(playback) -> Animator(frame_playback.reset(playback))
  }
}

/// Increase speed (decrease frame duration) by 50ms.
pub fn increase_speed(animator: Animator) -> Animator {
  case animator {
    Animator(playback) -> Animator(frame_playback.increase_speed(playback))
  }
}

/// Decrease speed (increase frame duration) by 50ms.
pub fn decrease_speed(animator: Animator) -> Animator {
  case animator {
    Animator(playback) -> Animator(frame_playback.decrease_speed(playback))
  }
}

/// Get frame duration in milliseconds.
pub fn get_frame_duration_ms(animator: Animator) -> Float {
  case animator {
    Animator(playback) -> frame_playback.frame_duration_ms(playback)
  }
}

/// Get current elapsed time in milliseconds.
pub fn get_elapsed_ms(animator: Animator) -> Float {
  case animator {
    Animator(playback) -> frame_playback.elapsed_ms(playback)
  }
}

/// Check if animator is currently running.
pub fn is_running(animator: Animator) -> Bool {
  case animator {
    Animator(playback) -> frame_playback.is_running(playback)
  }
}

/// Format speed as FPS (frames per second).
pub fn fps(animator: Animator) -> Float {
  case animator {
    Animator(playback) -> frame_playback.fps(playback)
  }
}

/// Format current state for display.
pub fn format_status(animator: Animator) -> String {
  let state = case is_running(animator) {
    True -> "running"
    False -> "paused"
  }
  let frame = current_frame(animator)
  let fps_val = float.truncate(fps(animator))
  "frame: "
  <> int.to_string(frame)
  <> "/"
  <> int.to_string(frame_count(animator))
  <> "  "
  <> state
  <> "  "
  <> int.to_string(fps_val)
  <> " FPS"
}

fn frame_count(animator: Animator) -> Int {
  case animator {
    Animator(frame_playback.Playback(_, _, _, frame_count)) -> frame_count
  }
}
