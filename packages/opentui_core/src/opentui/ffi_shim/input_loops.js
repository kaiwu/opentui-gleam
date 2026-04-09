const DEMO_INPUT_TIMEOUT_MS = 20

function utf8CharLength(byte) {
  if (byte < 0x80) return 1
  if (byte >= 0xc2 && byte <= 0xdf) return 2
  if (byte >= 0xe0 && byte <= 0xef) return 3
  if (byte >= 0xf0 && byte <= 0xf4) return 4
  return 0
}

function scanEscTerminatedSequence(buffer, start) {
  let i = start + 2

  while (i < buffer.length) {
    if (buffer[i] === 0x07) {
      return i + 1
    }

    if (buffer[i] === 0x1b) {
      if (i + 1 >= buffer.length) {
        return -1
      }

      if (buffer[i + 1] === 0x5c) {
        return i + 2
      }
    }

    i += 1
  }

  return -1
}

function scanCsiSequence(buffer, start) {
  let i = start + 2

  while (i < buffer.length) {
    const byte = buffer[i]
    if (byte >= 0x40 && byte <= 0x7e) {
      return i + 1
    }
    i += 1
  }

  return -1
}

function parseInputToken(buffer, start) {
  const byte = buffer[start]

  if (byte === 0x03) {
    return { next: start + 1, token: "\x03" }
  }

  if (byte === 0x0d || byte === 0x0a) {
    return { next: start + 1, token: "\n" }
  }

  if (byte === 0x08 || byte === 0x7f) {
    return { next: start + 1, token: "\x7f" }
  }

  if (byte === 0x1b) {
    if (start + 1 >= buffer.length) {
      return null
    }

    const next = buffer[start + 1]

    if (next === 0x5b) {
      const end = scanCsiSequence(buffer, start)
      if (end === -1) {
        return null
      }
      return { next: end, token: buffer.subarray(start, end).toString("utf-8") }
    }

    if (next === 0x5d || next === 0x50 || next === 0x5e || next === 0x5f) {
      const end = scanEscTerminatedSequence(buffer, start)
      if (end === -1) {
        return null
      }
      return { next: end, token: buffer.subarray(start, end).toString("utf-8") }
    }

    const width = utf8CharLength(next)
    if (width > 0) {
      if (start + 1 + width > buffer.length) {
        return null
      }
      const end = start + 1 + width
      return { next: end, token: buffer.subarray(start, end).toString("utf-8") }
    }

    return { next: start + 1, token: "\u001b" }
  }

  const width = utf8CharLength(byte)
  if (width === 0) {
    return { next: start + 1, token: buffer.subarray(start, start + 1).toString("utf-8") }
  }

  if (start + width > buffer.length) {
    return null
  }

  const end = start + width
  return { next: end, token: buffer.subarray(start, end).toString("utf-8") }
}

function cleanupAndExit(raw, rendererPtr) {
  try {
    process.stdin.setRawMode?.(false)
  } catch (_) {}

  raw.destroyRenderer(rendererPtr)
  process.exit(0)
}

function scheduleStartupRerenders(raw, rendererPtr, drawFn) {
  setTimeout(() => {
    drawFn()
    raw.render(rendererPtr, true)
  }, 0)

  setTimeout(() => {
    drawFn()
    raw.render(rendererPtr, true)
  }, 16)
}

function chunkRequestsExit(chunk) {
  return chunk.includes("q") || chunk.includes("\x03")
}

function makeLoop(raw, renderer, onChunk, drawFn, onTick) {
  scheduleStartupRerenders(raw, renderer, drawFn)

  let inputBuffer = Buffer.alloc(0)
  let inputTimer = null
  let tickState = typeof onTick === "function" ? { last: Date.now() } : null

  const flushBuffer = () => {
    if (inputBuffer.length === 0) return

    let offset = 0
    while (offset < inputBuffer.length) {
      const parsed = parseInputToken(inputBuffer, offset)
      if (parsed === null) break
      onChunk(parsed.token)
      offset = parsed.next
    }

    inputBuffer = inputBuffer.subarray(offset)
  }

  const onData = chunk => {
    const bufferChunk = Buffer.isBuffer(chunk) ? chunk : Buffer.from(chunk)
    const chunkText = bufferChunk.toString("utf-8")

    if (chunkRequestsExit(chunkText)) {
      process.stdin.off("data", onData)
      cleanupAndExit(raw, renderer)
      return
    }

    inputBuffer = Buffer.concat([inputBuffer, bufferChunk])

    if (inputTimer !== null) {
      clearTimeout(inputTimer)
    }

    inputTimer = setTimeout(() => {
      inputTimer = null
      flushBuffer()
      drawFn()
      raw.render(renderer, true)
    }, DEMO_INPUT_TIMEOUT_MS)
  }

  process.stdin.on("data", onData)

  if (tickState !== null) {
    const interval = setInterval(() => {
      const now = Date.now()
      const dt = now - tickState.last
      tickState.last = now
      onTick(dt)
      drawFn()
      raw.render(renderer, true)
    }, 16)

    process.on("exit", () => clearInterval(interval))
  }
}

export function runDemoLoop(raw, renderer, drawFn) {
  makeLoop(raw, renderer, () => {}, drawFn)
}

export function runEditorLoop(raw, renderer, onKey, drawFn) {
  makeLoop(raw, renderer, onKey, drawFn)
}

export function runEventLoop(raw, renderer, onEvent, drawFn) {
  makeLoop(raw, renderer, onEvent, drawFn)
}

export function runRawInputLoop(raw, renderer, onChunk, drawFn) {
  makeLoop(raw, renderer, onChunk, drawFn)
}

export function runAnimatedLoop(raw, renderer, onKey, onTick, drawFn) {
  makeLoop(raw, renderer, onKey, drawFn, onTick)
}
