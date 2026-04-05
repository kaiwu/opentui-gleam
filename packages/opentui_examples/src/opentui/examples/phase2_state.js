export function createIntCell(initial) {
  return { value: initial | 0 };
}

export function getIntCell(cell) {
  return cell.value | 0;
}

export function setIntCell(cell, value) {
  cell.value = value | 0;
}

export function createBoolCell(initial) {
  return { value: !!initial };
}

export function getBoolCell(cell) {
  return !!cell.value;
}

export function setBoolCell(cell, value) {
  cell.value = !!value;
}
