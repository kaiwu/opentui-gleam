export function toFloat32Buf(arr) {
  return new Float32Array(arr)
}

export function toBuf(str) {
  return Buffer.from(str, "utf-8")
}

export function readUtf8FromGetter(getRawLen, maxCapacity = 65536) {
  let capacity = 4096

  while (capacity <= maxCapacity) {
    const outBuf = Buffer.alloc(capacity)
    const rawLen = getRawLen(outBuf, capacity)
    const len = Number(rawLen)

    if (!Number.isFinite(len) || len <= 0) {
      return ""
    }

    if (len < capacity) {
      return outBuf.subarray(0, Math.floor(len)).toString("utf-8")
    }

    capacity *= 2
  }

  const outBuf = Buffer.alloc(maxCapacity)
  const rawLen = getRawLen(outBuf, maxCapacity)
  const len = Number(rawLen)

  if (!Number.isFinite(len) || len <= 0) {
    return ""
  }

  return outBuf.subarray(0, Math.min(outBuf.length, Math.floor(len))).toString("utf-8")
}
