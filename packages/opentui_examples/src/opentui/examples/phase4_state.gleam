pub type FloatCell

@external(javascript, "./phase4_state.js", "createFloatCell")
pub fn create_float(initial: Float) -> FloatCell

@external(javascript, "./phase4_state.js", "getFloatCell")
pub fn get_float(cell: FloatCell) -> Float

@external(javascript, "./phase4_state.js", "setFloatCell")
pub fn set_float(cell: FloatCell, value: Float) -> Nil
