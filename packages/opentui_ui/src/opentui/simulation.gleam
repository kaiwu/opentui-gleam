import opentui/timeline

pub type AutoState {
  AutoState(enabled: Bool, paused: Bool, interval: timeline.Interval)
}

pub type TickResult {
  TickResult(state: AutoState, firings: Int)
}

pub fn create(interval: timeline.Interval) -> AutoState {
  AutoState(True, False, interval)
}

pub fn tick(state: AutoState, dt_ms: Float) -> TickResult {
  case state.paused {
    True -> TickResult(state, 0)
    False ->
      case state.enabled {
        True -> {
          let timeline.TickResult(interval, firings) =
            timeline.tick(state.interval, dt_ms)
          TickResult(AutoState(..state, interval: interval), firings)
        }
        False ->
          TickResult(
            AutoState(..state, interval: timeline.reset(state.interval)),
            0,
          )
      }
  }
}

pub fn toggle_enabled(state: AutoState) -> AutoState {
  AutoState(
    ..state,
    enabled: !state.enabled,
    interval: timeline.reset(state.interval),
  )
}

pub fn toggle_paused(state: AutoState) -> AutoState {
  AutoState(..state, paused: !state.paused)
}

pub fn reset_interval(state: AutoState) -> AutoState {
  AutoState(..state, interval: timeline.reset(state.interval))
}

pub fn is_enabled(state: AutoState) -> Bool {
  state.enabled
}

pub fn is_paused(state: AutoState) -> Bool {
  state.paused
}

pub fn interval(state: AutoState) -> timeline.Interval {
  state.interval
}
