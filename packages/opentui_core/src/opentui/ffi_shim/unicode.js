import { toArrayBuffer } from "bun:ffi"
import { toBuf } from "./marshal.js"

// Unicode encoding — stateful: encode stores results, then query by index.
// WARNING: _encodedChars is module-global mutable state. This is safe only in
// single-threaded synchronous usage (one encodeUnicodeLength call, then
// encodeUnicodeCharAt/WidthAt queries, before the next encode call).
// Do not interleave concurrent encode sequences.
let _encodedChars = []

export function encodeUnicodeLength(raw, text, textLen, widthMethod) {
  _encodedChars = []
  const textBuf = toBuf(text)
  const outPtrSlot = new Float64Array(1)
  const outLenSlot = new Float64Array(1)
  const ok = raw.encodeUnicode(textBuf, textLen, outPtrSlot, outLenSlot, widthMethod)
  if (!ok) {
    return 0
  }
  const lenView = new DataView(outLenSlot.buffer)
  const charsLen = Number(lenView.getBigUint64(0, true))
  if (charsLen === 0) {
    return 0
  }
  const ptrView = new DataView(outPtrSlot.buffer)
  const charsPtrNum = Number(ptrView.getBigUint64(0, true))
  const byteLen = charsLen * 8
  const ab = toArrayBuffer(charsPtrNum, 0, byteLen)
  const view = new DataView(ab)
  for (let i = 0; i < charsLen; i++) {
    const base = i * 8
    const width = view.getUint8(base)
    const char = view.getUint32(base + 4, true)
    _encodedChars.push({ char, width })
  }
  raw.freeUnicode(charsPtrNum, charsLen)
  return charsLen
}

export function encodeUnicodeCharAt(index) {
  if (index < 0 || index >= _encodedChars.length) return 0
  return _encodedChars[index].char
}

export function encodeUnicodeWidthAt(index) {
  if (index < 0 || index >= _encodedChars.length) return 0
  return _encodedChars[index].width
}
