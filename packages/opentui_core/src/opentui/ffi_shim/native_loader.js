import { dlopen, FFIType, suffix } from "bun:ffi"
import { existsSync } from "fs"
import { join, dirname } from "path"
import { fileURLToPath } from "url"

const __dirname = dirname(fileURLToPath(import.meta.url))

const archMap = { x64: "x86_64", arm64: "aarch64" }
const osMap = { darwin: "macos", linux: "linux", win32: "windows" }
const arch = archMap[process.arch] || process.arch
const os = osMap[process.platform] || process.platform
const targetDir = `${arch}-${os}`
const npmPackageSuffix = `${process.platform}-${process.arch}`

function collectBaseDirs() {
  const dirs = new Set()
  dirs.add(process.cwd())

  let current = __dirname
  for (let i = 0; i < 8; i += 1) {
    dirs.add(current)
    const parent = join(current, "..")
    if (parent === current) break
    current = parent
  }

  return [...dirs]
}

function resolveNativeLibraryPath() {
  const baseDirs = collectBaseDirs()
  const libName = `libopentui.${suffix}`
  const altLibName = `opentui.${suffix}`
  const npmPkg = `@opentui/core-${npmPackageSuffix}`
  const submoduleLib = join("native", "opentui-zig", "packages", "core", "src", "zig", "lib", targetDir, libName)
  const submoduleZigOut = join("native", "opentui-zig", "packages", "core", "src", "zig", "zig-out", "lib", libName)

  const candidates = []

  for (const base of baseDirs) {
    candidates.push(join(base, submoduleLib))
    candidates.push(join(base, submoduleZigOut))
    candidates.push(join(base, "..", "..", submoduleLib))
    candidates.push(join(base, "..", "..", submoduleZigOut))
    candidates.push(join(base, "node_modules", npmPkg, libName))
    candidates.push(join(base, "node_modules", npmPkg, altLibName))
    candidates.push(join(base, "..", "..", "node_modules", npmPkg, libName))
    candidates.push(join(base, "..", "..", "node_modules", npmPkg, altLibName))
    candidates.push(join(base, "..", "opentui_core", "node_modules", npmPkg, libName))
    candidates.push(join(base, "..", "opentui_core", "node_modules", npmPkg, altLibName))
  }

  for (const candidate of candidates) {
    if (existsSync(candidate)) {
      return candidate
    }
  }

  throw new Error(
    `Native library not found. Expected one of:\n${candidates.join("\n")}\nBuild from submodule with ./scripts/build-native.sh or install the matching native npm package.`,
  )
}

export function loadRawSymbols() {
  const libPath = resolveNativeLibraryPath()

  return dlopen(libPath, {
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
    destroyFrameBuffer: {
      args: [FFIType.ptr],
      returns: FFIType.void,
    },
    drawFrameBuffer: {
      args: [FFIType.ptr, FFIType.i32, FFIType.i32, FFIType.ptr, FFIType.u32, FFIType.u32, FFIType.u32, FFIType.u32],
      returns: FFIType.void,
    },
    bufferResize: {
      args: [FFIType.ptr, FFIType.u32, FFIType.u32],
      returns: FFIType.void,
    },
    getBufferWidth: {
      args: [FFIType.ptr],
      returns: FFIType.u32,
    },
    getBufferHeight: {
      args: [FFIType.ptr],
      returns: FFIType.u32,
    },
    encodeUnicode: {
      args: [FFIType.ptr, FFIType.u64, FFIType.ptr, FFIType.ptr, FFIType.u8],
      returns: FFIType.bool,
    },
    freeUnicode: {
      args: [FFIType.ptr, FFIType.u64],
      returns: FFIType.void,
    },
    setLogCallback: {
      args: [FFIType.ptr],
      returns: FFIType.void,
    },
    setEventCallback: {
      args: [FFIType.ptr],
      returns: FFIType.void,
    },
  }).symbols
}
