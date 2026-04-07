import gleam/float
import gleam/int

pub type Interval {
  Interval(enabled: Bool, period_ms: Float, elapsed_ms: Float)
}

pub type TickResult {
  TickResult(interval: Interval, firings: Int)
}

pub fn every(period_ms: Float) -> Interval {
  Interval(enabled: True, period_ms: clamp_period(period_ms), elapsed_ms: 0.0)
}

pub fn pause(interval: Interval) -> Interval {
  Interval(..interval, enabled: False)
}

pub fn resume(interval: Interval) -> Interval {
  Interval(..interval, enabled: True)
}

pub fn toggle(interval: Interval) -> Interval {
  Interval(..interval, enabled: !interval.enabled)
}

pub fn reset(interval: Interval) -> Interval {
  Interval(..interval, elapsed_ms: 0.0)
}

pub fn set_enabled(interval: Interval, enabled: Bool) -> Interval {
  Interval(..interval, enabled: enabled)
}

pub fn tick(interval: Interval, dt_ms: Float) -> TickResult {
  case interval.enabled {
    False -> TickResult(interval, 0)
    True -> {
      let total = interval.elapsed_ms +. dt_ms
      let firings = float_to_non_negative_int(total /. interval.period_ms)
      let remainder = total -. interval.period_ms *. int_to_float(firings)
      TickResult(Interval(..interval, elapsed_ms: remainder), firings)
    }
  }
}

pub fn is_enabled(interval: Interval) -> Bool {
  interval.enabled
}

pub fn elapsed_ms(interval: Interval) -> Float {
  interval.elapsed_ms
}

pub fn period_ms(interval: Interval) -> Float {
  interval.period_ms
}

fn clamp_period(period_ms: Float) -> Float {
  case period_ms <. 1.0 {
    True -> 1.0
    False -> period_ms
  }
}

fn float_to_non_negative_int(value: Float) -> Int {
  case value <. 0.0 {
    True -> 0
    False -> float.truncate(value)
  }
}

fn int_to_float(value: Int) -> Float {
  int.to_float(value)
}
