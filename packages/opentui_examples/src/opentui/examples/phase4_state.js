export function createFloatCell(initial) {
  return { value: +initial };
}

export function getFloatCell(cell) {
  return +cell.value;
}

export function setFloatCell(cell, value) {
  cell.value = +value;
}

export function createGenericCell(initial) {
  return { value: initial };
}

export function getGenericCell(cell) {
  return cell.value;
}

export function setGenericCell(cell, value) {
  cell.value = value;
}
