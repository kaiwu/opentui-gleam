// native/ffi-shim.js
// Single dlopen call — exports flat functions for Gleam @external declarations
import { dlopen, FFIType, suffix } from "bun:ffi"
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

const libPath = join(__dirname, "..", "priv", "lib", targetDir, `libopentui${suffix}`)

if (!existsSync(libPath)) {
  throw new Error(`Native library not found: ${libPath}\nRun: ./scripts/build-native.sh`)
}

const { symbols } = dlopen(libPath, {
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

// === Demo Helpers (JS-side) ===

export function log(msg) {
  console.log(msg)
}

let stdinRawMode = false

export function startStdinReader() {
  if (stdinRawMode) return
  // Put stdin in raw mode to get individual keypresses
  if (process.stdin.isTTY) {
    process.stdin.setRawMode(true)
  }
  process.stdin.resume()
  stdinRawMode = true
}

export function readStdin() {
  // Synchronous blocking read — one byte at a time
  const buf = Buffer.alloc(1)
  const fd = process.stdin.fd
  const { readSync } = require("fs")
  try {
    // readSync blocks until data is available
    const bytesRead = readSync(fd, buf, 0, 1, null)
    if (bytesRead > 0) {
      const ch = buf.toString("utf-8")
      if (ch === "\x03") process.exit() // Ctrl+C
      return ch
    }
  } catch (e) {
    // EAGAIN or other errors
  }
  return ""
}

// Re-export as individual named functions for Gleam @external
export const createRenderer = symbols.createRenderer
export const destroyRenderer = symbols.destroyRenderer
export const render = symbols.render
export const resizeRenderer = symbols.resizeRenderer
export const setupTerminal = symbols.setupTerminal
export const suspendRenderer = symbols.suspendRenderer
export const resumeRenderer = symbols.resumeRenderer
export const createOptimizedBuffer = symbols.createOptimizedBuffer
export const destroyOptimizedBuffer = symbols.destroyOptimizedBuffer
export const bufferClear = symbols.bufferClear
export const bufferDrawText = symbols.bufferDrawText
export const bufferFillRect = symbols.bufferFillRect
export const bufferSetCell = symbols.bufferSetCell
export const bufferPushScissorRect = symbols.bufferPushScissorRect
export const bufferPopScissorRect = symbols.bufferPopScissorRect
export const bufferPushOpacity = symbols.bufferPushOpacity
export const bufferPopOpacity = symbols.bufferPopOpacity
export const getNextBuffer = symbols.getNextBuffer
export const setTerminalTitle = symbols.setTerminalTitle
export const enableMouse = symbols.enableMouse
export const disableMouse = symbols.disableMouse
export const enableKittyKeyboard = symbols.enableKittyKeyboard
export const disableKittyKeyboard = symbols.disableKittyKeyboard
export const setCursorPosition = symbols.setCursorPosition
export const copyToClipboardOSC52 = symbols.copyToClipboardOSC52
export const addToHitGrid = symbols.addToHitGrid
export const clearCurrentHitGrid = symbols.clearCurrentHitGrid
export const checkHit = symbols.checkHit
export const createTextBuffer = symbols.createTextBuffer
export const destroyTextBuffer = symbols.destroyTextBuffer
export const textBufferAppend = symbols.textBufferAppend
export const textBufferClear = symbols.textBufferClear
export const textBufferGetLength = symbols.textBufferGetLength
export const textBufferGetPlainText = symbols.textBufferGetPlainText
export const createEditBuffer = symbols.createEditBuffer
export const destroyEditBuffer = symbols.destroyEditBuffer
export const editBufferSetText = symbols.editBufferSetText
export const editBufferInsertText = symbols.editBufferInsertText
export const editBufferGetText = symbols.editBufferGetText
export const editBufferUndo = symbols.editBufferUndo
export const editBufferRedo = symbols.editBufferRedo
export const editBufferCanUndo = symbols.editBufferCanUndo
export const editBufferCanRedo = symbols.editBufferCanRedo
export const createEditorView = symbols.createEditorView
export const destroyEditorView = symbols.destroyEditorView
export const editorViewSetViewport = symbols.editorViewSetViewport
export const bufferDrawEditorView = symbols.bufferDrawEditorView
export const createSyntaxStyle = symbols.createSyntaxStyle
export const destroySyntaxStyle = symbols.destroySyntaxStyle
export const syntaxStyleRegister = symbols.syntaxStyleRegister
export const setLogCallback = symbols.setLogCallback
export const setEventCallback = symbols.setEventCallback
