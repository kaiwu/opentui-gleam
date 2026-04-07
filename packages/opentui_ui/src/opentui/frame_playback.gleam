import gleam/float
import gleam/int

pub type Playback {
  Playback(
    running: Bool,
    elapsed_ms: Float,
    frame_duration_ms: Float,
    frame_count: Int,
  )
}

pub fn create(frame_count: Int, frame_duration_ms: Float) -> Playback {
  Playback(True, 0.0, clamp_duration(frame_duration_ms), frame_count)
}

pub fn clamp_duration(d: Float) -> Float {
  float.min(float.max(d, 50.0), 2000.0)
}

pub fn tick(playback: Playback, dt_ms: Float) -> Playback {
  case playback.running {
    True -> Playback(..playback, elapsed_ms: playback.elapsed_ms +. dt_ms)
    False -> playback
  }
}

pub fn pause(playback: Playback) -> Playback {
  Playback(..playback, running: False)
}

pub fn resume(playback: Playback) -> Playback {
  Playback(..playback, running: True)
}

pub fn toggle_running(playback: Playback) -> Playback {
  Playback(..playback, running: !playback.running)
}

pub fn current_frame(playback: Playback) -> Int {
  let cycle_length =
    playback.frame_duration_ms *. int.to_float(playback.frame_count)
  let normalized_time = playback.elapsed_ms /. cycle_length
  let frame =
    float.truncate(normalized_time *. int.to_float(playback.frame_count))
  frame % playback.frame_count
}

pub fn step_frame(playback: Playback) -> Playback {
  Playback(
    ..playback,
    elapsed_ms: playback.elapsed_ms +. playback.frame_duration_ms,
  )
}

pub fn reset(playback: Playback) -> Playback {
  Playback(..playback, running: True, elapsed_ms: 0.0)
}

pub fn increase_speed(playback: Playback) -> Playback {
  Playback(
    ..playback,
    frame_duration_ms: clamp_duration(playback.frame_duration_ms -. 50.0),
  )
}

pub fn decrease_speed(playback: Playback) -> Playback {
  Playback(
    ..playback,
    frame_duration_ms: clamp_duration(playback.frame_duration_ms +. 50.0),
  )
}

pub fn fps(playback: Playback) -> Float {
  1000.0 /. playback.frame_duration_ms
}

pub fn is_running(playback: Playback) -> Bool {
  playback.running
}

pub fn elapsed_ms(playback: Playback) -> Float {
  playback.elapsed_ms
}

pub fn frame_duration_ms(playback: Playback) -> Float {
  playback.frame_duration_ms
}
