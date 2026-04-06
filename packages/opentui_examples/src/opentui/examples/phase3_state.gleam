pub type StringCell

@external(javascript, "./phase3_state.js", "createStringCell")
pub fn create_string(initial: String) -> StringCell

@external(javascript, "./phase3_state.js", "getStringCell")
pub fn get_string(cell: StringCell) -> String

@external(javascript, "./phase3_state.js", "setStringCell")
pub fn set_string(cell: StringCell, value: String) -> Nil
