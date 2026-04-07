export function createFloatCell(initial) {
  return { value: +initial };
}

export function getFloatCell(cell) {
  return +cell.value;
}

export function setFloatCell(cell, value) {
  cell.value = +value;
}
