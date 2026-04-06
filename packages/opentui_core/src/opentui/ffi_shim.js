import { dlopen, FFIType, suffix, ptr } from "bun:ffi"
import { existsSync } from "fs"
import { join, dirname } from "path"
import { fileURLToPath } from "url"
const __dirname = dirname(fileURLToPath(import.meta.url))

if (process.env.OPENTUI_FORCE_EXPLICIT_WIDTH === undefined) {
  process.env.OPENTUI_FORCE_EXPLICIT_WIDTH = "false"
}

const archMap = { x64: "x86_64", arm64: "aarch64" }
const osMap = { darwin: "macos", linux: "linux", win32: "windows" }
const arch = archMap[process.arch] || process.arch
const os = osMap[process.platform] || process.platform
const targetDir = `${arch}-${os}`
const npmPackageSuffix = `${process.platform}-${process.arch}`

function resolveProjectRoot() {
  const candidates = [process.cwd()]
  let current = __dirname

  for (let i = 0; i < 8; i += 1) {
    candidates.push(current)
    const parent = join(current, "..")
    if (parent === current) {
      break
    }
    current = parent
  }

  for (const candidate of candidates) {
    const hasGleamToml = existsSync(join(candidate, "gleam.toml"))
    const hasSubmodule = existsSync(join(candidate, "native", "opentui-zig")) || existsSync(join(candidate, "..", "..", "native", "opentui-zig"))
    const hasNativePackages = existsSync(join(candidate, "node_modules", "@opentui"))

    if (hasGleamToml && (hasSubmodule || hasNativePackages)) {
      return candidate
    }
  }

  throw new Error("Could not locate opentui-gleam project root for FFI loading")
}

function resolveNativeLibraryPath() {
  const root = resolveProjectRoot()
  const submoduleCandidates = [
    join(root, "native", "opentui-zig", "packages", "core", "src", "zig", "lib", targetDir, `libopentui.${suffix}`),
    join(root, "native", "opentui-zig", "packages", "core", "src", "zig", "zig-out", "lib", `libopentui.${suffix}`),
    join(root, "..", "..", "native", "opentui-zig", "packages", "core", "src", "zig", "lib", targetDir, `libopentui.${suffix}`),
    join(root, "..", "..", "native", "opentui-zig", "packages", "core", "src", "zig", "zig-out", "lib", `libopentui.${suffix}`),
  ]
  const npmCandidates = [
    join(root, "node_modules", "@opentui", `core-${npmPackageSuffix}`, `libopentui.${suffix}`),
    join(root, "node_modules", "@opentui", `core-${npmPackageSuffix}`, `opentui.${suffix}`),
  ]
  const candidates = [...submoduleCandidates, ...npmCandidates]

  for (const candidate of candidates) {
    if (existsSync(candidate)) {
      return candidate
    }
  }

  throw new Error(
    `Native library not found. Expected one of:\n${candidates.join("\n")}\nBuild from submodule with ./scripts/build-native.sh or install the matching native npm package.`,
  )
}

const libPath = resolveNativeLibraryPath()

const { symbols: raw } = dlopen(libPath, {
  // === Renderer Lifecycle ===
  createRenderer: {
    args: [FFIType.u32, FFIType.u32, FFIType.bool, FFIType.bool],
    returns: FFIType.ptr,
  },
  destroyRenderer: {
    args: [FFIType.ptr],
    returns: FFIType.void,
  },
  render: {
    args: [FFIType.ptr, FFIType.bool],
    returns: FFIType.void,
  },
  resizeRenderer: {
    args: [FFIType.ptr, FFIType.u32, FFIType.u32],
    returns: FFIType.void,
  },
  setupTerminal: {
    args: [FFIType.ptr, FFIType.bool],
    returns: FFIType.void,
  },
  suspendRenderer: {
    args: [FFIType.ptr],
    returns: FFIType.void,
  },
  resumeRenderer: {
    args: [FFIType.ptr],
    returns: FFIType.void,
  },

  // === Buffer ===
  createOptimizedBuffer: {
    args: [FFIType.u32, FFIType.u32, FFIType.bool, FFIType.u8, FFIType.ptr, FFIType.u64],
    returns: FFIType.ptr,
  },
  destroyOptimizedBuffer: {
    args: [FFIType.ptr],
    returns: FFIType.void,
  },
  bufferClear: {
    args: [FFIType.ptr, FFIType.ptr],
    returns: FFIType.void,
  },
  bufferDrawText: {
    args: [FFIType.ptr, FFIType.ptr, FFIType.u64, FFIType.u32, FFIType.u32, FFIType.ptr, FFIType.ptr, FFIType.u32],
    returns: FFIType.void,
  },
  bufferFillRect: {
    args: [FFIType.ptr, FFIType.u32, FFIType.u32, FFIType.u32, FFIType.u32, FFIType.ptr],
    returns: FFIType.void,
  },
  bufferSetCell: {
    args: [FFIType.ptr, FFIType.u32, FFIType.u32, FFIType.u32, FFIType.ptr, FFIType.ptr, FFIType.u32],
    returns: FFIType.void,
  },
  bufferPushScissorRect: {
    args: [FFIType.ptr, FFIType.i32, FFIType.i32, FFIType.u32, FFIType.u32],
    returns: FFIType.void,
  },
  bufferPopScissorRect: {
    args: [FFIType.ptr],
    returns: FFIType.void,
  },
  bufferPushOpacity: {
    args: [FFIType.ptr, FFIType.f32],
    returns: FFIType.void,
  },
  bufferPopOpacity: {
    args: [FFIType.ptr],
    returns: FFIType.void,
  },
  getNextBuffer: {
    args: [FFIType.ptr],
    returns: FFIType.ptr,
  },

  // === Terminal ===
  setTerminalTitle: {
    args: [FFIType.ptr, FFIType.ptr, FFIType.u64],
    returns: FFIType.void,
  },
  enableMouse: {
    args: [FFIType.ptr, FFIType.bool],
    returns: FFIType.void,
  },
  disableMouse: {
    args: [FFIType.ptr],
    returns: FFIType.void,
  },
  enableKittyKeyboard: {
    args: [FFIType.ptr, FFIType.u8],
    returns: FFIType.void,
  },
  disableKittyKeyboard: {
    args: [FFIType.ptr],
    returns: FFIType.void,
  },
  setCursorPosition: {
    args: [FFIType.ptr, FFIType.i32, FFIType.i32, FFIType.bool],
    returns: FFIType.void,
  },
  copyToClipboardOSC52: {
    args: [FFIType.u8, FFIType.ptr, FFIType.u64],
    returns: FFIType.bool,
  },

  // === Hit Grid (Mouse) ===
  addToHitGrid: {
    args: [FFIType.ptr, FFIType.i32, FFIType.i32, FFIType.u32, FFIType.u32, FFIType.u32],
    returns: FFIType.void,
  },
  clearCurrentHitGrid: {
    args: [FFIType.ptr],
    returns: FFIType.void,
  },
  checkHit: {
    args: [FFIType.ptr, FFIType.u32, FFIType.u32],
    returns: FFIType.u32,
  },

  // === TextBuffer ===
  createTextBuffer: {
    args: [FFIType.u8],
    returns: FFIType.ptr,
  },
  destroyTextBuffer: {
    args: [FFIType.ptr],
    returns: FFIType.void,
  },
  textBufferAppend: {
    args: [FFIType.ptr, FFIType.ptr, FFIType.u64],
    returns: FFIType.void,
  },
  textBufferClear: {
    args: [FFIType.ptr],
    returns: FFIType.void,
  },
  textBufferGetLength: {
    args: [FFIType.ptr],
    returns: FFIType.u32,
  },
  textBufferGetPlainText: {
    args: [FFIType.ptr, FFIType.ptr, FFIType.u64],
    returns: FFIType.u64,
  },

  // === EditBuffer ===
  createEditBuffer: {
    args: [FFIType.u8],
    returns: FFIType.ptr,
  },
  destroyEditBuffer: {
    args: [FFIType.ptr],
    returns: FFIType.void,
  },
  editBufferSetText: {
    args: [FFIType.ptr, FFIType.ptr, FFIType.u64],
    returns: FFIType.void,
  },
  editBufferInsertText: {
    args: [FFIType.ptr, FFIType.ptr, FFIType.u64],
    returns: FFIType.void,
  },
  editBufferGetText: {
    args: [FFIType.ptr, FFIType.ptr, FFIType.u64],
    returns: FFIType.u64,
  },
  editBufferUndo: {
    args: [FFIType.ptr, FFIType.ptr, FFIType.u64],
    returns: FFIType.u64,
  },
  editBufferRedo: {
    args: [FFIType.ptr, FFIType.ptr, FFIType.u64],
    returns: FFIType.u64,
  },
  editBufferCanUndo: {
    args: [FFIType.ptr],
    returns: FFIType.bool,
  },
  editBufferCanRedo: {
    args: [FFIType.ptr],
    returns: FFIType.bool,
  },
  editBufferInsertChar: {
    args: [FFIType.ptr, FFIType.ptr, FFIType.u64],
    returns: FFIType.void,
  },
  editBufferDeleteCharBackward: {
    args: [FFIType.ptr],
    returns: FFIType.void,
  },
  editBufferDeleteChar: {
    args: [FFIType.ptr],
    returns: FFIType.void,
  },
  editBufferMoveCursorLeft: {
    args: [FFIType.ptr],
    returns: FFIType.void,
  },
  editBufferMoveCursorRight: {
    args: [FFIType.ptr],
    returns: FFIType.void,
  },
  editBufferMoveCursorUp: {
    args: [FFIType.ptr],
    returns: FFIType.void,
  },
  editBufferMoveCursorDown: {
    args: [FFIType.ptr],
    returns: FFIType.void,
  },
  editBufferNewLine: {
    args: [FFIType.ptr],
    returns: FFIType.void,
  },
  editBufferGetCursor: {
    args: [FFIType.ptr, FFIType.ptr, FFIType.ptr],
    returns: FFIType.void,
  },

  // === EditorView ===
  createEditorView: {
    args: [FFIType.ptr, FFIType.u32, FFIType.u32],
    returns: FFIType.ptr,
  },
  destroyEditorView: {
    args: [FFIType.ptr],
    returns: FFIType.void,
  },
  editorViewSetViewport: {
    args: [FFIType.ptr, FFIType.u32, FFIType.u32, FFIType.u32, FFIType.u32, FFIType.bool],
    returns: FFIType.void,
  },
  bufferDrawEditorView: {
    args: [FFIType.ptr, FFIType.ptr, FFIType.i32, FFIType.i32],
    returns: FFIType.void,
  },

  // === SyntaxStyle ===
  createSyntaxStyle: {
    args: [],
    returns: FFIType.ptr,
  },
  destroySyntaxStyle: {
    args: [FFIType.ptr],
    returns: FFIType.void,
  },
  syntaxStyleRegister: {
    args: [FFIType.ptr, FFIType.ptr, FFIType.u64, FFIType.ptr, FFIType.ptr, FFIType.u32],
    returns: FFIType.u32,
  },

  // === Callbacks ===
  setLogCallback: {
    args: [FFIType.ptr],
    returns: FFIType.void,
  },
  setEventCallback: {
    args: [FFIType.ptr],
    returns: FFIType.void,
  },
})

// ── Helpers ──

// Gleam sends List(Float) as JS arrays. Convert to Float64Array for ptr args.
function toFloat32Buf(arr) {
  return new Float32Array(arr)
}

// Gleam sends String as JS string. Convert to Buffer for ptr args.
function toBuf(str) {
  return Buffer.from(str, "utf-8")
}

// ── Wrapped exports ──

// Pure numeric: pass through directly
export const createRenderer = raw.createRenderer
export const destroyRenderer = raw.destroyRenderer
export const render = raw.render
export const resizeRenderer = raw.resizeRenderer
export function setupTerminal(renderer, useAlternateScreen) {
  if (process.stdin.isTTY) {
    process.stdin.setRawMode(true)
  }
  process.stdin.resume()
  raw.setupTerminal(renderer, useAlternateScreen)
}
export const suspendRenderer = raw.suspendRenderer
export const resumeRenderer = raw.resumeRenderer
export const destroyOptimizedBuffer = raw.destroyOptimizedBuffer
export const bufferPushScissorRect = raw.bufferPushScissorRect
export const bufferPopScissorRect = raw.bufferPopScissorRect
export const bufferPushOpacity = raw.bufferPushOpacity
export const bufferPopOpacity = raw.bufferPopOpacity
export const getNextBuffer = raw.getNextBuffer
export const enableMouse = raw.enableMouse
export const disableMouse = raw.disableMouse
export const enableKittyKeyboard = raw.enableKittyKeyboard
export const disableKittyKeyboard = raw.disableKittyKeyboard
export const setCursorPosition = raw.setCursorPosition
export const addToHitGrid = raw.addToHitGrid
export const clearCurrentHitGrid = raw.clearCurrentHitGrid
export const checkHit = raw.checkHit
export const createTextBuffer = raw.createTextBuffer
export const destroyTextBuffer = raw.destroyTextBuffer
export const textBufferClear = raw.textBufferClear
export const textBufferGetLength = raw.textBufferGetLength
export const createEditBuffer = raw.createEditBuffer
export const destroyEditBuffer = raw.destroyEditBuffer
export const editBufferCanUndo = raw.editBufferCanUndo
export const editBufferCanRedo = raw.editBufferCanRedo
export const createEditorView = raw.createEditorView
export const destroyEditorView = raw.destroyEditorView
export const editorViewSetViewport = raw.editorViewSetViewport
export const bufferDrawEditorView = raw.bufferDrawEditorView
export const createSyntaxStyle = raw.createSyntaxStyle
export const destroySyntaxStyle = raw.destroySyntaxStyle

// String-accepting: convert strings to Buffers

export function createOptimizedBuffer(width, height, respectAlpha, widthMethod, id, idLen) {
  return raw.createOptimizedBuffer(width, height, respectAlpha, widthMethod, toBuf(id), idLen)
}

export function bufferClear(buffer, bg) {
  raw.bufferClear(buffer, toFloat32Buf(bg))
}

export function bufferDrawText(buffer, text, textLen, x, y, fg, bg, attributes) {
  raw.bufferDrawText(buffer, toBuf(text), textLen, x, y, toFloat32Buf(fg), toFloat32Buf(bg), attributes)
}

export function bufferFillRect(buffer, x, y, width, height, bg) {
  raw.bufferFillRect(buffer, x, y, width, height, toFloat32Buf(bg))
}

export function bufferSetCell(buffer, x, y, ch, fg, bg, attributes) {
  raw.bufferSetCell(buffer, x, y, ch, toFloat32Buf(fg), toFloat32Buf(bg), attributes)
}

export function setTerminalTitle(renderer, title, titleLen) {
  raw.setTerminalTitle(renderer, toBuf(title), titleLen)
}

export function copyToClipboardOSC52(clipboardType, text, textLen) {
  return raw.copyToClipboardOSC52(clipboardType, toBuf(text), textLen)
}

export function textBufferAppend(buffer, text, textLen) {
  raw.textBufferAppend(buffer, toBuf(text), textLen)
}

export function textBufferGetPlainText(buffer, output, outputLen) {
  return raw.textBufferGetPlainText(buffer, toBuf(output), outputLen)
}

export function editBufferSetText(buffer, text, textLen) {
  raw.editBufferSetText(buffer, toBuf(text), textLen)
}

export function editBufferInsertText(buffer, text, textLen) {
  raw.editBufferInsertText(buffer, toBuf(text), textLen)
}

export function editBufferGetText(buffer, output, outputLen) {
  return raw.editBufferGetText(buffer, toBuf(output), outputLen)
}

export function editBufferUndo(buffer, output, outputLen) {
  return raw.editBufferUndo(buffer, toBuf(output), outputLen)
}

export function editBufferRedo(buffer, output, outputLen) {
  return raw.editBufferRedo(buffer, toBuf(output), outputLen)
}

export function editBufferInsertChar(buffer, char, charLen) {
  raw.editBufferInsertChar(buffer, toBuf(char), charLen)
}

export const editBufferDeleteCharBackward = raw.editBufferDeleteCharBackward
export const editBufferDeleteChar = raw.editBufferDeleteChar
export const editBufferMoveCursorLeft = raw.editBufferMoveCursorLeft
export const editBufferMoveCursorRight = raw.editBufferMoveCursorRight
export const editBufferMoveCursorUp = raw.editBufferMoveCursorUp
export const editBufferMoveCursorDown = raw.editBufferMoveCursorDown
export const editBufferNewLine = raw.editBufferNewLine

export function editBufferGetCursor(buffer) {
  const rowBuf = new Uint32Array(1)
  const colBuf = new Uint32Array(1)
  raw.editBufferGetCursor(buffer, rowBuf, colBuf)
  return [rowBuf[0], colBuf[0]]
}

export function editBufferGetTextAsString(buffer) {
  let capacity = 4096

  while (capacity <= 65536) {
    const outBuf = Buffer.alloc(capacity)
    const rawLen = raw.editBufferGetText(buffer, outBuf, capacity)
    const len = Number(rawLen)

    if (!Number.isFinite(len) || len <= 0) {
      return ""
    }

    if (len < capacity) {
      return outBuf.subarray(0, Math.floor(len)).toString("utf-8")
    }

    capacity *= 2
  }

  const outBuf = Buffer.alloc(65536)
  const rawLen = raw.editBufferGetText(buffer, outBuf, 65536)
  const len = Number(rawLen)

  if (!Number.isFinite(len) || len <= 0) {
    return ""
  }

  return outBuf.subarray(0, Math.min(outBuf.length, Math.floor(len))).toString("utf-8")
}

export function textBufferGetPlainTextAsString(buffer) {
  let capacity = 4096

  while (capacity <= 65536) {
    const outBuf = Buffer.alloc(capacity)
    const rawLen = raw.textBufferGetPlainText(buffer, outBuf, capacity)
    const len = Number(rawLen)

    if (!Number.isFinite(len) || len <= 0) {
      return ""
    }

    if (len < capacity) {
      return outBuf.subarray(0, Math.floor(len)).toString("utf-8")
    }

    capacity *= 2
  }

  const outBuf = Buffer.alloc(65536)
  const rawLen = raw.textBufferGetPlainText(buffer, outBuf, 65536)
  const len = Number(rawLen)

  if (!Number.isFinite(len) || len <= 0) {
    return ""
  }

  return outBuf.subarray(0, Math.min(outBuf.length, Math.floor(len))).toString("utf-8")
}

export function syntaxStyleRegister(style, name, nameLen, fg, bg, attributes) {
  return raw.syntaxStyleRegister(style, toBuf(name), nameLen, toFloat32Buf(fg), toFloat32Buf(bg), attributes)
}

// Callbacks — wrap to convert C-string args to JS strings
export function setLogCallback(callback) {
  raw.setLogCallback(callback)
}

export function setEventCallback(callback) {
  raw.setEventCallback(callback)
}

// === Demo Helpers (JS-side) ===

export function log(msg) {
  console.log(msg)
}

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

    const nextByte = buffer[start + 1]

    if (nextByte === 0x4f) {
      if (start + 2 >= buffer.length) {
        return null
      }

      switch (buffer[start + 2]) {
        case 0x41:
          return { next: start + 3, token: "\x1b[A" }
        case 0x42:
          return { next: start + 3, token: "\x1b[B" }
        case 0x43:
          return { next: start + 3, token: "\x1b[C" }
        case 0x44:
          return { next: start + 3, token: "\x1b[D" }
        default:
          return { next: start + 3, token: null }
      }
    }

    if (nextByte === 0x5b) {
      const end = scanCsiSequence(buffer, start)
      if (end === -1) {
        return null
      }

      const finalByte = buffer[end - 1]
      if (finalByte === 0x41) return { next: end, token: "\x1b[A" }
      if (finalByte === 0x42) return { next: end, token: "\x1b[B" }
      if (finalByte === 0x43) return { next: end, token: "\x1b[C" }
      if (finalByte === 0x44) return { next: end, token: "\x1b[D" }

      return {
        next: end,
        token: buffer.subarray(start, end).toString("utf-8"),
      }
    }

    if (nextByte === 0x5d || nextByte === 0x50 || nextByte === 0x5f || nextByte === 0x5e) {
      const end = scanEscTerminatedSequence(buffer, start)
      if (end === -1) {
        return null
      }

      return { next: end, token: null }
    }

    if (nextByte >= 0x20 && nextByte <= 0x7e) {
      return { next: start + 2, token: String.fromCharCode(nextByte) }
    }

    return { next: start + 2, token: null }
  }

  if (byte < 0x20) {
    return { next: start + 1, token: null }
  }

  if (byte < 0x80) {
    return { next: start + 1, token: String.fromCharCode(byte) }
  }

  const charLength = utf8CharLength(byte)
  if (charLength === 0) {
    return { next: start + 1, token: null }
  }

  if (start + charLength > buffer.length) {
    return null
  }

  return {
    next: start + charLength,
    token: buffer.subarray(start, start + charLength).toString("utf-8"),
  }
}

class DemoInputParser {
  constructor() {
    this.pending = Buffer.alloc(0)
    this.flushTimer = null
  }

  push(chunk, onToken) {
    this.pending = this.pending.length === 0 ? Buffer.from(chunk) : Buffer.concat([this.pending, chunk])
    this.clearFlushTimer()

    let offset = 0
    while (offset < this.pending.length) {
      const parsed = parseInputToken(this.pending, offset)
      if (parsed === null) {
        break
      }

      offset = parsed.next
      if (parsed.token !== null) {
        onToken(parsed.token)
      }
    }

    this.pending = offset === 0 ? this.pending : this.pending.subarray(offset)

    if (this.pending.length > 0) {
      this.flushTimer = setTimeout(() => {
        this.pending = Buffer.alloc(0)
        this.flushTimer = null
      }, DEMO_INPUT_TIMEOUT_MS)
    }
  }

  clearFlushTimer() {
    if (this.flushTimer !== null) {
      clearTimeout(this.flushTimer)
      this.flushTimer = null
    }
  }
}

function cleanupAndExit(rendererPtr) {
  raw.disableMouse(rendererPtr)
  raw.destroyRenderer(rendererPtr)
  if (process.stdin.isTTY) {
    process.stdin.setRawMode(false)
  }
  process.stdin.pause()
  process.exit(0)
}

function scheduleStartupRerenders(rendererPtr, drawFn) {
  const timers = [
    setTimeout(() => {
      drawFn()
      raw.render(rendererPtr, true)
    }, 40),
    setTimeout(() => {
      drawFn()
      raw.render(rendererPtr, true)
    }, 140),
  ]

  return () => {
    for (const timer of timers) {
      clearTimeout(timer)
    }
  }
}

function chunkRequestsExit(chunk) {
  return chunk.length === 1 && (chunk[0] === 0x03 || chunk[0] === 0x71)
}

// Run the demo loop: draws the frame, then listens for keys.
// On each keypress, calls drawFn() and re-renders.
// Quits when 'q' is pressed.
export function runDemoLoop(renderer, drawFn) {
  const r = Number(renderer) // Gleam opaque -> Int -> JS number
  const parser = new DemoInputParser()
  const cancelStartupRerenders = scheduleStartupRerenders(r, drawFn)

  // Initial render
  drawFn()
  raw.render(r, true)

  // Raw mode stdin
  if (process.stdin.isTTY) {
    process.stdin.setRawMode(true)
  }
  process.stdin.resume()

  process.stdin.on("data", (chunk) => {
    parser.push(chunk, (token) => {
      if (token === "\x03" || token === "q") {
        cancelStartupRerenders()
        cleanupAndExit(r)
      }
    })
    drawFn()
    raw.render(r, true)
  })
}

// Run the editor loop: passes keypresses to onKey, then calls drawFn and re-renders.
export function runEditorLoop(renderer, onKey, drawFn) {
  const r = Number(renderer)
  const parser = new DemoInputParser()
  const cancelStartupRerenders = scheduleStartupRerenders(r, drawFn)

  // Initial render
  drawFn()
  raw.render(r, true)

  // Raw mode stdin
  if (process.stdin.isTTY) {
    process.stdin.setRawMode(true)
  }
  process.stdin.resume()

  process.stdin.on("data", (chunk) => {
    parser.push(chunk, (token) => {
      if (token === "\x03" || token === "q") {
        cancelStartupRerenders()
        cleanupAndExit(r)
      }
      onKey(token)
    })
    drawFn()
    raw.render(r, true)
  })
}

export function runEventLoop(renderer, onEvent, drawFn) {
  const r = Number(renderer)
  const parser = new DemoInputParser()
  const cancelStartupRerenders = scheduleStartupRerenders(r, drawFn)

  drawFn()
  raw.render(r, true)

  if (process.stdin.isTTY) {
    process.stdin.setRawMode(true)
  }
  process.stdin.resume()

  process.stdin.on("data", (chunk) => {
    parser.push(chunk, (token) => {
      if (token === "\x03" || token === "q") {
        cancelStartupRerenders()
        cleanupAndExit(r)
      }
      onEvent(token)
    })
    drawFn()
    raw.render(r, true)
  })
}

export function runRawInputLoop(renderer, onChunk, drawFn) {
  const r = Number(renderer)
  const cancelStartupRerenders = scheduleStartupRerenders(r, drawFn)

  drawFn()
  raw.render(r, true)

  if (process.stdin.isTTY) {
    process.stdin.setRawMode(true)
  }
  process.stdin.resume()

  process.stdin.on("data", (chunk) => {
    if (chunkRequestsExit(chunk)) {
      cancelStartupRerenders()
      cleanupAndExit(r)
    }
    onChunk(Buffer.from(chunk).toString("utf-8"))
    drawFn()
    raw.render(r, true)
  })
}
