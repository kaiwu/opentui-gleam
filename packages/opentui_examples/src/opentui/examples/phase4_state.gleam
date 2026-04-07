pub type FloatCell

@external(javascript, "./phase4_state.js", "createFloatCell")
pub fn create_float(initial: Float) -> FloatCell

@external(javascript, "./phase4_state.js", "getFloatCell")
pub fn get_float(cell: FloatCell) -> Float

@external(javascript, "./phase4_state.js", "setFloatCell")
pub fn set_float(cell: FloatCell, value: Float) -> Nil

/// Mutable cell for holding any opaque value (used for Animator in demos).
pub type GenericCell

@external(javascript, "./phase4_state.js", "createGenericCell")
pub fn create_generic(initial: a) -> GenericCell

@external(javascript, "./phase4_state.js", "getGenericCell")
pub fn get_generic(cell: GenericCell) -> a

@external(javascript, "./phase4_state.js", "setGenericCell")
pub fn set_generic(cell: GenericCell, value: a) -> Nil
