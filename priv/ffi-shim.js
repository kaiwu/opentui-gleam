// native/ffi-shim.js
// Single dlopen call — exports flat functions for Gleam @external declarations
import { dlopen, FFIType, suffix, ptr } from "bun:ffi"
import { existsSync } from "fs"
import { join, dirname } from "path"
import { fileURLToPath } from "url"

const __dirname = dirname(fileURLToPath(import.meta.url))

// Resolve platform-specific library
const archMap = { x64: "x86_64", arm64: "aarch64" }
const osMap = { darwin: "macos", linux: "linux", win32: "windows" }
const arch = archMap[process.arch] || process.arch
const os = osMap[process.platform] || process.platform
const targetDir = `${arch}-${os}`

const libPath = join(__dirname, "..", "priv", "lib", targetDir, `libopentui.${suffix}`)

if (!existsSync(libPath)) {
  throw new Error(`Native library not found: ${libPath}\nRun: ./scripts/build-native.sh`)
}

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
function toFloat64Buf(arr) {
  return new Float64Array(arr)
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
export const setupTerminal = raw.setupTerminal
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
  raw.bufferClear(buffer, toFloat64Buf(bg))
}

export function bufferDrawText(buffer, text, textLen, x, y, fg, bg, attributes) {
  raw.bufferDrawText(buffer, toBuf(text), textLen, x, y, toFloat64Buf(fg), toFloat64Buf(bg), attributes)
}

export function bufferFillRect(buffer, x, y, width, height, bg) {
  raw.bufferFillRect(buffer, x, y, width, height, toFloat64Buf(bg))
}

export function bufferSetCell(buffer, x, y, ch, fg, bg, attributes) {
  raw.bufferSetCell(buffer, x, y, ch, toFloat64Buf(fg), toFloat64Buf(bg), attributes)
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
  const outBuf = Buffer.alloc(4096)
  const len = raw.editBufferGetText(buffer, outBuf, 4096)
  return outBuf.subarray(0, len).toString("utf-8")
}

export function syntaxStyleRegister(style, name, nameLen, fg, bg, attributes) {
  return raw.syntaxStyleRegister(style, toBuf(name), nameLen, toFloat64Buf(fg), toFloat64Buf(bg), attributes)
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

// Run the demo loop: draws the frame, then listens for keys.
// On each keypress, calls drawFn() and re-renders.
// Quits when 'q' is pressed.
export function runDemoLoop(renderer, drawFn) {
  const r = Number(renderer) // Gleam opaque -> Int -> JS number

  // Initial render
  drawFn()
  raw.render(r, true)

  // Raw mode stdin
  if (process.stdin.isTTY) {
    process.stdin.setRawMode(true)
  }
  process.stdin.setEncoding("utf-8")
  process.stdin.resume()

  process.stdin.on("data", (key) => {
    if (key === "\x03" || key === "q") {
      // Ctrl+C or 'q' — cleanup and exit
      raw.disableMouse(r)
      raw.destroyRenderer(r)
      if (process.stdin.isTTY) {
        process.stdin.setRawMode(false)
      }
      process.stdin.pause()
      process.exit(0)
    }
    // Any other key — redraw
    drawFn()
    raw.render(r, true)
  })
}

// Run the editor loop: passes keypresses to onKey, then calls drawFn and re-renders.
export function runEditorLoop(renderer, onKey, drawFn) {
  const r = Number(renderer)

  // Initial render
  drawFn()
  raw.render(r, true)

  // Raw mode stdin
  if (process.stdin.isTTY) {
    process.stdin.setRawMode(true)
  }
  process.stdin.setEncoding("utf-8")
  process.stdin.resume()

  process.stdin.on("data", (key) => {
    if (key === "\x03" || key === "q") {
      // Ctrl+C or 'q' — cleanup and exit
      raw.disableMouse(r)
      raw.destroyRenderer(r)
      if (process.stdin.isTTY) {
        process.stdin.setRawMode(false)
      }
      process.stdin.pause()
      process.exit(0)
    }
    // Pass key to editor, then redraw
    onKey(key)
    drawFn()
    raw.render(r, true)
  })
}
