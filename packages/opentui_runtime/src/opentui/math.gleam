@external(javascript, "./math_ffi.js", "sin")
pub fn sin(x: Float) -> Float

@external(javascript, "./math_ffi.js", "cos")
pub fn cos(x: Float) -> Float

@external(javascript, "./math_ffi.js", "sqrt")
pub fn sqrt(x: Float) -> Float

@external(javascript, "./math_ffi.js", "atan2")
pub fn atan2(y: Float, x: Float) -> Float

@external(javascript, "./math_ffi.js", "pow")
pub fn pow(base: Float, exp: Float) -> Float

@external(javascript, "./math_ffi.js", "pi")
pub fn pi() -> Float
