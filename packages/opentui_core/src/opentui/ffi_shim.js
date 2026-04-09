import { loadRawSymbols } from "./ffi_shim/native_loader.js"
import { readUtf8FromGetter, toBuf, toFloat32Buf } from "./ffi_shim/marshal.js"
import {
  encodeUnicodeCharAt as queryEncodedUnicodeCharAt,
  encodeUnicodeLength as storeEncodedUnicodeLength,
  encodeUnicodeWidthAt as queryEncodedUnicodeWidthAt,
} from "./ffi_shim/unicode.js"
import {
  runAnimatedLoop as runAnimatedLoopImpl,
  runDemoLoop as runDemoLoopImpl,
  runEditorLoop as runEditorLoopImpl,
  runEventLoop as runEventLoopImpl,
  runRawInputLoop as runRawInputLoopImpl,
} from "./ffi_shim/input_loops.js"

if (process.env.OPENTUI_FORCE_EXPLICIT_WIDTH === undefined) {
  process.env.OPENTUI_FORCE_EXPLICIT_WIDTH = "false"
}

const raw = loadRawSymbols()

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
export const destroyFrameBuffer = raw.destroyFrameBuffer
export const drawFrameBuffer = raw.drawFrameBuffer
export const bufferResize = raw.bufferResize
export const getBufferWidth = raw.getBufferWidth
export const getBufferHeight = raw.getBufferHeight

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
  return readUtf8FromGetter((outBuf, capacity) => raw.editBufferGetText(buffer, outBuf, capacity))
}

export function textBufferGetPlainTextAsString(buffer) {
  return readUtf8FromGetter((outBuf, capacity) => raw.textBufferGetPlainText(buffer, outBuf, capacity))
}

export function syntaxStyleRegister(style, name, nameLen, fg, bg, attributes) {
  return raw.syntaxStyleRegister(style, toBuf(name), nameLen, toFloat32Buf(fg), toFloat32Buf(bg), attributes)
}

export function encodeUnicodeLength(text, textLen, widthMethod) {
  return storeEncodedUnicodeLength(raw, text, textLen, widthMethod)
}

export function encodeUnicodeCharAt(index) {
  return queryEncodedUnicodeCharAt(index)
}

export function encodeUnicodeWidthAt(index) {
  return queryEncodedUnicodeWidthAt(index)
}

export function setLogCallback(callback) {
  raw.setLogCallback(callback)
}

export function setEventCallback(callback) {
  raw.setEventCallback(callback)
}

export function log(msg) {
  console.log(msg)
}

export function runDemoLoop(renderer, drawFn) {
  runDemoLoopImpl(raw, renderer, drawFn)
}

export function runEditorLoop(renderer, onKey, drawFn) {
  runEditorLoopImpl(raw, renderer, onKey, drawFn)
}

export function runEventLoop(renderer, onEvent, drawFn) {
  runEventLoopImpl(raw, renderer, onEvent, drawFn)
}

export function runRawInputLoop(renderer, onChunk, drawFn) {
  runRawInputLoopImpl(raw, renderer, onChunk, drawFn)
}

export function runAnimatedLoop(renderer, onKey, onTick, drawFn) {
  runAnimatedLoopImpl(raw, renderer, onKey, onTick, drawFn)
}
