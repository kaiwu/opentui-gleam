pub type IntCell

pub type BoolCell

@external(javascript, "./phase2_state.js", "createIntCell")
pub fn create_int(initial: Int) -> IntCell

@external(javascript, "./phase2_state.js", "getIntCell")
pub fn get_int(cell: IntCell) -> Int

@external(javascript, "./phase2_state.js", "setIntCell")
pub fn set_int(cell: IntCell, value: Int) -> Nil

@external(javascript, "./phase2_state.js", "createBoolCell")
pub fn create_bool(initial: Bool) -> BoolCell

@external(javascript, "./phase2_state.js", "getBoolCell")
pub fn get_bool(cell: BoolCell) -> Bool

@external(javascript, "./phase2_state.js", "setBoolCell")
pub fn set_bool(cell: BoolCell, value: Bool) -> Nil
