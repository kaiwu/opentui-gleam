pub type WidthMethod {
  Normal
  Half
  Cjk
}

pub fn width_method_to_int(method: WidthMethod) -> Int {
  case method {
    Normal -> 0
    Half -> 1
    Cjk -> 2
  }
}
