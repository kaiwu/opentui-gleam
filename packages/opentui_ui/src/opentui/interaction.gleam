pub type DragRegion {
  DragRegion(left: Int, top: Int, width: Int, height: Int)
}

pub type DragBounds {
  DragBounds(min_left: Int, min_top: Int, max_left: Int, max_top: Int)
}

pub type DragSession {
  DragSession(active: Bool, offset_x: Int, offset_y: Int)
}

pub fn region(left: Int, top: Int, width: Int, height: Int) -> DragRegion {
  DragRegion(left, top, width, height)
}

pub fn bounds(
  min_left: Int,
  min_top: Int,
  max_left: Int,
  max_top: Int,
) -> DragBounds {
  DragBounds(min_left, min_top, max_left, max_top)
}

pub fn idle_drag() -> DragSession {
  DragSession(False, 0, 0)
}

pub fn hit_test(target: DragRegion, x: Int, y: Int) -> Bool {
  x >= target.left
  && x < target.left + target.width
  && y >= target.top
  && y < target.top + target.height
}

pub fn begin_drag(
  session: DragSession,
  target: DragRegion,
  pointer_x: Int,
  pointer_y: Int,
) -> DragSession {
  case hit_test(target, pointer_x, pointer_y) {
    True ->
      DragSession(
        active: True,
        offset_x: pointer_x - target.left,
        offset_y: pointer_y - target.top,
      )
    False -> session
  }
}

pub fn drag_to(
  session: DragSession,
  drag_bounds: DragBounds,
  pointer_x: Int,
  pointer_y: Int,
) -> DragRegion {
  case session.active {
    False -> DragRegion(drag_bounds.min_left, drag_bounds.min_top, 0, 0)
    True ->
      DragRegion(
        left: clamp_int(
          pointer_x - session.offset_x,
          drag_bounds.min_left,
          drag_bounds.max_left,
        ),
        top: clamp_int(
          pointer_y - session.offset_y,
          drag_bounds.min_top,
          drag_bounds.max_top,
        ),
        width: 0,
        height: 0,
      )
  }
}

pub fn end_drag(session: DragSession) -> DragSession {
  DragSession(..session, active: False)
}

pub fn clamp_region(target: DragRegion, drag_bounds: DragBounds) -> DragRegion {
  DragRegion(
    left: clamp_int(target.left, drag_bounds.min_left, drag_bounds.max_left),
    top: clamp_int(target.top, drag_bounds.min_top, drag_bounds.max_top),
    width: target.width,
    height: target.height,
  )
}

fn clamp_int(value: Int, low: Int, high: Int) -> Int {
  case value < low {
    True -> low
    False ->
      case value > high {
        True -> high
        False -> value
      }
  }
}
