export function createStringCell(initial) {
  return { value: initial };
}

export function getStringCell(cell) {
  return cell.value;
}

export function setStringCell(cell, value) {
  cell.value = value;
}
