# OpenTUI Gleam Bindings — Project Structure

## Architecture Overview

```
┌─────────────────────────────────────┐
│           Gleam demos/apps          │
├─────────────────────────────────────┤
│   opentui/examples/* runnable mains │  ← `gleam run -m ...`
├─────────────────────────────────────┤
│   opentui/* Gleam bindings/runtime  │  ← composable Gleam APIs
├─────────────────────────────────────┤
│   opentui/ffi.gleam                 │  ← raw `@external` boundary
├─────────────────────────────────────┤
│   src/opentui/ffi_shim.js           │  ← single Bun FFI shim
├─────────────────────────────────────┤
│   native/opentui-zig/.../zig/lib/*  │  ← compiled native library
├─────────────────────────────────────┤
│   native/opentui-zig/               │  ← upstream Zig/TS source of truth
│       └── packages/core/src/zig/    │
│           └── lib.zig (C API)       │
└─────────────────────────────────────┘
```

**Why a JS shim?** `bun:ffi` requires a single `dlopen()` call that declares all symbols upfront. Gleam's `@external` can only call individual JS functions — it cannot do `dlopen` itself. The shim bridges this gap.

**Current direction:** this repo is evolving toward a Gleam ecosystem, not a single hardcoded demo. The default `gleam run` entrypoint is a catalog/help surface, while each demo remains directly runnable as its own module.

**Native library resolution:** the shim first tries the locally built submodule output under `native/opentui-zig/packages/core/src/zig/lib/<target>/`. If that does not exist, it falls back to the matching prebuilt native npm package under `node_modules/@opentui/core-<platform>-<arch>/`. The package suffix is chosen from `process.platform` and `process.arch`, for example `linux-x64` on this machine.

---

## Directory Structure

```
opentui-gleam/
├── gleam.toml
├── manifest.toml
├── package.json                      # Optional native npm package fallback declarations
├── README.md
│
├── AGENTS.md                         # Project direction and architecture notes
├── src/                              # Gleam source code
│   ├── opentui.gleam                 # Default catalog/help entrypoint
│   └── opentui/
│       ├── ffi.gleam                 # Low-level @external declarations (raw FFI)
│       ├── runtime.gleam             # JS-loop/runtime helpers above raw FFI
│       ├── buffer.gleam              # Buffer drawing API
│       ├── renderer.gleam            # Renderer operations
│       ├── edit_buffer.gleam         # Editable text buffer wrapper
│       ├── text.gleam                # Pure text wrapping/truncation helpers
│       ├── types.gleam               # Shared enums/constants
│       ├── catalog.gleam             # Demo registry/help text
│       └── examples/
│           ├── common.gleam          # Shared demo chrome/bootstrap helpers
│           └── editor.gleam          # Runnable editor demo (`gleam run -m opentui/examples/editor`)
│
├── native/
│   ├── ffi-shim.js                   # JS shim — dlopen + symbol declarations
│   └── opentui-zig/                  # Git submodule → upstream OpenTUI repo
│       ├── build.zig
│       ├── build.zig.zon
│       └── packages/core/src/zig/
│           ├── lib.zig               # ← The C API (237 export fn declarations)
│           ├── renderer.zig
│           ├── buffer.zig
│           ├── terminal.zig
│           ├── text-buffer.zig
│           ├── edit-buffer.zig
│           ├── editor-view.zig
│           └── ...                   # ← All other .zig source files
│
├── scripts/
│   └── build-native.sh               # Builds Zig shared library in the submodule output tree
│
└── test/
    ├── opentui_test.gleam
    └── opentui_catalog_test.gleam
```

## Running demos

```bash
# Show the demo catalog
gleam run

# Run a specific demo directly
gleam run -m opentui/examples/editor

# Optional: install a prebuilt native library instead of building from the submodule
npm install

# This will install the matching optional native package for the current platform,
# for example @opentui/core-linux-x64 on Linux x64.
```

New demos should be added under `src/opentui/examples/` and registered in `src/opentui/catalog.gleam`.

Current demos include:

- `opentui/examples/editor`
- `opentui/examples/terminal_title`
- `opentui/examples/text_wrap`
- `opentui/examples/text_truncation`

---

## Layer 1: JS Shim (`src/opentui/ffi_shim.js`)

Single `dlopen` call, exports flat functions for Gleam `@external`:

```js
// src/opentui/ffi_shim.js
import { dlopen, FFIType, suffix } from "bun:ffi"
import { existsSync } from "fs"
import { join, dirname } from "path"
import { fileURLToPath } from "url"

const __dirname = dirname(fileURLToPath(import.meta.url))

// Resolve platform-specific library
const platform = `${process.platform}-${process.arch}`
// Map bun arch names to zig build output names
const archMap = { x64: "x86_64", arm64: "aarch64" }
const osMap = { darwin: "macos", linux: "linux", win32: "windows" }
const arch = archMap[process.arch] || process.arch
const os = osMap[process.platform] || process.platform
const targetDir = `${arch}-${os}`

const libPath = join(process.cwd(), "native", "opentui-zig", "packages", "core", "src", "zig", "lib", targetDir, `libopentui.${suffix}`)

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

  // ... add remaining ~200 symbols following the same pattern
})

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
```

---

## Layer 2: Gleam FFI Declarations (`src/ffi.gleam`)

Raw `@external` declarations. Opaque handle types prevent mixing up pointers:

```gleam
// src/ffi.gleam

// ── Opaque Handle Types ──
// These are just Ints under the hood, but the type system prevents
// passing a Buffer where a Renderer is expected.

pub opaque type Renderer { Renderer(Int) }
pub opaque type Buffer { Buffer(Int) }
pub opaque type TextBuffer { TextBuffer(Int) }
pub opaque type EditBuffer { EditBuffer(Int) }
pub opaque type EditorView { EditorView(Int) }
pub opaque type SyntaxStyle { SyntaxStyle(Int) }

// ── Renderer Lifecycle ──

@external(javascript, "./ffi_shim.js", "createRenderer")
pub fn create_renderer(
  width: Int,
  height: Int,
  testing: Bool,
  remote: Bool,
) -> Int

@external(javascript, "./ffi_shim.js", "destroyRenderer")
pub fn destroy_renderer(renderer: Int) -> Nil

@external(javascript, "./ffi_shim.js", "render")
pub fn render_frame(renderer: Int, force: Bool) -> Nil

@external(javascript, "./ffi_shim.js", "resizeRenderer")
pub fn resize_renderer(renderer: Int, width: Int, height: Int) -> Nil

@external(javascript, "./ffi_shim.js", "setupTerminal")
pub fn setup_terminal(renderer: Int, use_alternate_screen: Bool) -> Nil

@external(javascript, "./ffi_shim.js", "suspendRenderer")
pub fn suspend_renderer(renderer: Int) -> Nil

@external(javascript, "./ffi_shim.js", "resumeRenderer")
pub fn resume_renderer(renderer: Int) -> Nil

// ── Buffer ──

@external(javascript, "./ffi_shim.js", "createOptimizedBuffer")
pub fn create_buffer(
  width: Int,
  height: Int,
  respect_alpha: Bool,
  width_method: Int,
  id: String,
  id_len: Int,
) -> Int

@external(javascript, "./ffi_shim.js", "destroyOptimizedBuffer")
pub fn destroy_buffer(buffer: Int) -> Nil

@external(javascript, "./ffi_shim.js", "bufferClear")
pub fn buffer_clear(buffer: Int, bg: List(Float)) -> Nil

@external(javascript, "./ffi_shim.js", "bufferDrawText")
pub fn buffer_draw_text(
  buffer: Int,
  text: String,
  text_len: Int,
  x: Int,
  y: Int,
  fg: List(Float),
  bg: List(Float),
  attributes: Int,
) -> Nil

@external(javascript, "./ffi_shim.js", "bufferFillRect")
pub fn buffer_fill_rect(
  buffer: Int,
  x: Int,
  y: Int,
  width: Int,
  height: Int,
  bg: List(Float),
) -> Nil

@external(javascript, "./ffi_shim.js", "getNextBuffer")
pub fn get_next_buffer(renderer: Int) -> Int

// ── Terminal ──

@external(javascript, "./ffi_shim.js", "setTerminalTitle")
pub fn set_terminal_title(renderer: Int, title: String, title_len: Int) -> Nil

@external(javascript, "./ffi_shim.js", "enableMouse")
pub fn enable_mouse(renderer: Int, enable_movement: Bool) -> Nil

@external(javascript, "./ffi_shim.js", "disableMouse")
pub fn disable_mouse(renderer: Int) -> Nil

@external(javascript, "./ffi_shim.js", "enableKittyKeyboard")
pub fn enable_kitty_keyboard(renderer: Int, flags: Int) -> Nil

@external(javascript, "./ffi_shim.js", "disableKittyKeyboard")
pub fn disable_kitty_keyboard(renderer: Int) -> Nil

// ── Hit Grid ──

@external(javascript, "./ffi_shim.js", "addToHitGrid")
pub fn add_to_hit_grid(
  renderer: Int,
  x: Int,
  y: Int,
  width: Int,
  height: Int,
  id: Int,
) -> Nil

@external(javascript, "./ffi_shim.js", "clearCurrentHitGrid")
pub fn clear_hit_grid(renderer: Int) -> Nil

@external(javascript, "./ffi_shim.js", "checkHit")
pub fn check_hit(renderer: Int, x: Int, y: Int) -> Int
```

---

## Layer 3: Gleam Public API (`src/renderer.gleam`)

Wraps raw FFI with `Result` types, validation, and Gleam ergonomics:

```gleam
// src/renderer.gleam

import opentui/ffi.{type Renderer}
import opentui/types.{WidthMethod}

pub type ScreenMode {
  AlternateScreen
  MainScreen
  SplitFooter(Int)  // footer height in rows
}

pub type RendererConfig {
  RendererConfig(
    width: Int,
    height: Int,
    screen_mode: ScreenMode,
    exit_on_ctrl_c: Bool,
  )
}

pub fn create(config: RendererConfig) -> Result(Renderer, String) {
  let ptr = ffi.create_renderer(
    config.width,
    config.height,
    False,  // testing
    False,  // remote
  )
  case ptr {
    0 -> Error("Failed to create renderer — check terminal dimensions")
    p -> Ok(ffi.Renderer(p))
  }
}

pub fn destroy(renderer: Renderer) -> Nil {
  case renderer {
    ffi.Renderer(ptr) -> ffi.destroy_renderer(ptr)
  }
}

pub fn render(renderer: Renderer, force: Bool) -> Nil {
  case renderer {
    ffi.Renderer(ptr) -> ffi.render_frame(ptr, force)
  }
}

pub fn setup(renderer: Renderer, mode: ScreenMode) -> Nil {
  let use_alternate = case mode {
    AlternateScreen -> True
    _ -> False
  }
  case renderer {
    ffi.Renderer(ptr) -> ffi.setup_terminal(ptr, use_alternate)
  }
}
```

---

## Layer 4: Buffer API (`src/buffer.gleam`)

```gleam
// src/buffer.gleam

import opentui/ffi.{type Buffer, type Renderer}

pub fn create(
  width: Int,
  height: Int,
  respect_alpha: Bool,
  width_method: WidthMethod,
  id: String,
) -> Result(Buffer, String) {
  let ptr = ffi.create_buffer(
    width,
    height,
    respect_alpha,
    width_method |> width_method_to_int,
    id,
    id |> string.length,
  )
  case ptr {
    0 -> Error("Failed to create buffer")
    p -> Ok(ffi.Buffer(p))
  }
}

pub fn clear(buffer: Buffer, bg: #(Float, Float, Float, Float)) -> Nil {
  case buffer {
    ffi.Buffer(ptr) -> ffi.buffer_clear(ptr, bg_rgba_to_list(bg))
  }
}

pub fn draw_text(
  buffer: Buffer,
  text: String,
  x: Int,
  y: Int,
  fg: #(Float, Float, Float, Float),
  bg: #(Float, Float, Float, Float),
  attributes: Int,
) -> Nil {
  case buffer {
    ffi.Buffer(ptr) ->
      ffi.buffer_draw_text(
        ptr,
        text,
        text |> string.length,
        x,
        y,
        fg_rgba_to_list(fg),
        bg_rgba_to_list(bg),
        attributes,
      )
  }
}

pub fn fill_rect(
  buffer: Buffer,
  x: Int,
  y: Int,
  width: Int,
  height: Int,
  bg: #(Float, Float, Float, Float),
) -> Nil {
  case buffer {
    ffi.Buffer(ptr) ->
      ffi.buffer_fill_rect(ptr, x, y, width, height, bg_rgba_to_list(bg))
  }
}

pub fn get_next_buffer(renderer: Renderer) -> Buffer {
  case renderer {
    ffi.Renderer(ptr) -> ffi.Buffer(ffi.get_next_buffer(ptr))
  }
}

// ── Internal helpers ──

fn bg_rgba_to_list(c: #(Float, Float, Float, Float)) -> List(Float) {
  [c.0, c.1, c.2, c.3]
}

fn fg_rgba_to_list(c: #(Float, Float, Float, Float)) -> List(Float) {
  [c.0, c.1, c.2, c.3]
}
```

---

## Native Build Script (`scripts/build-native.sh`)

```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
ZIG_DIR="$ROOT_DIR/native/opentui-zig/packages/core/src/zig"
TARGET_OUTPUT_DIR="$ZIG_DIR/lib/$TARGET"

# Detect platform
ARCH=$(uname -m)
OS=$(uname -s | tr '[:upper:]' '[:lower:]')

# Map to zig target names
case "$ARCH" in
  x86_64) ZIG_ARCH="x86_64" ;;
  aarch64|arm64) ZIG_ARCH="aarch64" ;;
  *) echo "Unsupported architecture: $ARCH"; exit 1 ;;
esac

case "$OS" in
  darwin) ZIG_OS="macos" ;;
  linux) ZIG_OS="linux" ;;
  *) echo "Unsupported OS: $OS"; exit 1 ;;
esac

TARGET="${ZIG_ARCH}-${ZIG_OS}"
TARGET_OUTPUT_DIR="$OUTPUT_DIR/$TARGET"

echo "Building OpenTUI native library for $TARGET..."

cd "$ZIG_DIR"

# Build the native library
zig build -Doptimize=ReleaseSafe

# The Zig build installs the shared library directly into the submodule output tree
mkdir -p "$TARGET_OUTPUT_DIR"

# Find and copy the built library
if [ "$ZIG_OS" = "macos" ]; then
  cp "$ZIG_DIR/../lib/$TARGET/libopentui.dylib" "$TARGET_OUTPUT_DIR/" 2>/dev/null || \
  cp "$ZIG_DIR/zig-out/lib/libopentui.dylib" "$TARGET_OUTPUT_DIR/" 2>/dev/null || \
  echo "Warning: Could not find built library"
elif [ "$ZIG_OS" = "linux" ]; then
  cp "$ZIG_DIR/../lib/$TARGET/libopentui.so" "$TARGET_OUTPUT_DIR/" 2>/dev/null || \
  cp "$ZIG_DIR/zig-out/lib/libopentui.so" "$TARGET_OUTPUT_DIR/" 2>/dev/null || \
  echo "Warning: Could not find built library"
fi

echo "Native library built to $TARGET_OUTPUT_DIR"
```

---

## gleam.toml

```toml
name = "opentui"
version = "0.1.0"
gleam = ">= 1.6.0"

target = "javascript"

[javascript]
runtime = "bun"

[dependencies]
gleam_stdlib = ">= 0.44.0 and < 2.0.0"
gleam_json = ">= 2.0.0 and < 3.0.0"
```

---

## Keeping Zig in Sync

```bash
# Initial setup — add upstream as submodule
git submodule add https://github.com/anomalyco/opentui.git native/opentui-zig

# Update to latest upstream
cd native/opentui-zig
git checkout main
git pull
cd ../..
git add native/opentui-zig
git commit -m "Update opentui-zig to latest"

# Rebuild native library after update
./scripts/build-native.sh
```

---

## What You're Carrying vs Dropping

| OpenTUI Component | Status | Reason |
|---|---|---|
| `src/zig/` (all .zig files) | ✅ Keep (via submodule) | This is the C API you bind to |
| `build.zig` / `build.zig.zon` | ✅ Keep (via submodule) | Builds the .so/.dylib/.dll |
| `uucode` dependency | ✅ Keep (via submodule) | Pulled in by build.zig.zon |
| TypeScript bindings (`zig.ts`) | ❌ Drop | You replace this with Gleam |
| `@opentui/core` JS bundle | ❌ Drop | You replace this with Gleam |
| `@opentui/react` | ❌ Drop | Not relevant |
| `@opentui/solid` | ❌ Drop | Not relevant |
| `packages/web` | ❌ Drop | Not relevant |

---

## Build & Run Workflow

```bash
# 1. Initialize submodule (first time only)
git submodule update --init --recursive

# 2. Build native library
./scripts/build-native.sh

# 3. Fetch Gleam dependencies
gleam deps download

# 4. Build Gleam code
gleam build

# 5. Run
gleam run

# 6. Test
gleam test
```

---

## Key Design Decisions

| Decision | Rationale |
|---|---|
| **JS shim layer** | `bun:ffi` needs one `dlopen` with all symbols. Gleam `@external` can only call individual functions. The shim bridges this. |
| **Opaque handle types** | `ffi.Renderer(Int)` not bare `Int` — prevents passing a `Buffer` where a `Renderer` is expected. |
| **Git submodule for Zig** | Clean upstream tracking. `git submodule update --remote` pulls latest. No vendoring noise. |
| **Direct submodule library loading** | The shim loads the built shared library straight from `native/opentui-zig/packages/core/src/zig/lib/<target>/`. |
| **Separate `ffi.gleam` from public API** | Raw FFI is unsafe (returns 0 on failure, raw ints). Public modules wrap with `Result` types and validation. |
| **`Result` wrappers** | Every `create_*` function returns `Result(Handle, String)` — Gleam-idiomatic error handling instead of checking for null pointers. |
| **RGBA as tuples** | `#(Float, Float, Float, Float)` in Gleam, converted to `List(Float)` at FFI boundary. |

---

## Potential Gotchas

1. **String length**: Zig's C API expects `(ptr, len)` pairs for strings. Gleam strings are UTF-8, but `string.length` returns character count, not byte count. Use `string.byte_size` instead.

2. **`JSCallback` lifetime**: If you bind `setLogCallback` or `setEventCallback`, the `JSCallback` must stay alive or you get a segfault. Store it in a module-level variable, not a local.

3. **`build.zig` output path**: The upstream `build.zig` installs to `lib/{target}/` under `packages/core/src/zig/`. If upstream changes the path, update the shim resolver and build script.

4. **Platform detection**: The shim maps `process.arch` (`x64`/`arm64`) to Zig target names (`x86_64`/`aarch64`). If Bun ever changes these, update the map.

5. **Not all 237 functions need bindings**: Start with the subset you need (renderer lifecycle, buffer drawing, text editing). Add more as required.

---

## Revised Architecture: Two Paths

There are actually two viable approaches. The original "direct Zig FFI" path above is the harder one. Here's the comparison:

### Path A: Wrap `@opentui/core` (Recommended)

`@opentui/core` already ships on npm with the Zig FFI fully handled. You just add Gleam types on top.

```
opentui-gleam/
├── gleam.toml
├── src/
│   ├── opentui.gleam          # @external wrappers for @opentui/core exports
│   ├── renderer.gleam         # Gleam-idiomatic API
│   ├── types.gleam            # Gleam types mapped to JS shapes
│   └── element.gleam          # Virtual element ADT (see composability below)
└── test/
```

```gleam
// src/opentui.gleam — just wrap the existing JS API
@external(javascript, "@opentui/core", "createCliRenderer")
pub fn create_cli_renderer(config: JsConfig) -> Promise(Renderer)

@external(javascript, "@opentui/core", "BoxRenderable")
pub fn create_box(renderer: Renderer, options: JsBoxOptions) -> Box
```

**No Zig submodule. No `build-native.sh`. No custom `ffi_shim.js`.** Just `bun install @opentui/core` and declare `@external` functions.

### Path B: Direct Zig FFI (Original)

The full structure documented above — git submodule, JS shim, code generation, native build script. Use this if you need to track Zig HEAD, modify the Zig source, or avoid the `@opentui/core` npm package entirely.

| | Path A: Wrap `@opentui/core` | Path B: Direct Zig FFI |
|---|---|---|
| Setup | `bun install @opentui/core` | Submodule + build script + shim |
| Zig sync | `bun update @opentui/core` | `git submodule update` + rebuild |
| FFI layer | One `@external` per function | Three layers (shim + ffi.gleam + wrapper) |
| Code gen needed | No | Yes |
| Track Zig HEAD | No (npm release cadence) | Yes (direct submodule) |
| Modify Zig source | No | Yes |
| Bundle size | Includes full `@opentui/core` | Only what you bind |

---

## Functional Composability — The Real Advantage

OpenTUI's raw imperative API is inherently **not composable**:

```ts
// Imperative — zero composability, side effects everywhere
const buffer = renderer.getNextBuffer()
buffer.drawText("Login", 0, 0, fg, bg, 0)
buffer.fillRect(0, 2, 40, 1, border)
buffer.drawText("User:", 1, 3, fg, bg, 0)
renderer.render()
```

React adds composability via JSX, but that requires the React reconciler runtime. Gleam gives you composability **as pure data** — no framework needed:

```gleam
type Element {
  Box(List(Style), List(Element))
  Text(String, List(Style))
  Input(List(InputOption))
  Spacer
}

// Pure data — no side effects, no runtime
let login_form =
  Box([Padding(2), FlexColumn], [
    Text("Login Form", [Fg("#FFFF00"), Bold]),
    Box([Border, Width(40), Height(3)], [
      Input([Placeholder("Username"), Focused]),
    ]),
    Box([Border, Width(40), Height(3)], [
      Input([Placeholder("Password"), Masked]),
    ]),
  ])

// Transform freely — it's just data
let with_debug = add_debug_overlay(login_form)
let conditional = case is_loading {
  True -> add_spinner(login_form)
  False -> login_form
}
```

Then a single render pass walks the tree and calls the imperative FFI:

```gleam
fn render_element(buffer: Buffer, el: Element, x: Int, y: Int) -> #(Int, Int) {
  case el {
    Box(styles, children) -> render_box(buffer, styles, children, x, y)
    Text(content, styles) -> render_text(buffer, content, styles, x, y)
    Input(options) -> render_input(buffer, options, x, y)
    Spacer -> #(x, y)
  }
}
```

**The difference**: React's JSX is syntax sugar for `React.createElement()` calls — it still needs the React reconciler runtime. Gleam's `Element` type is just an algebraic data type. You can map over it, filter it, diff it, serialize it, transform it — all pure functions, no runtime overhead.

### Composition Patterns That Matter for TUIs

**1. Conditional rendering via `case`**

```gleam
let content = case state {
  Loading -> [Spinner()]
  Loaded(data) -> render_data(data)
  Error(msg) -> [ErrorBanner(msg)]
}
```

**2. Higher-order element transformers**

```gleam
// Wrap any element with a border and title
fn with_title(title: String, el: Element) -> Element {
  Box([Border, Title(title), Padding(1)], [el])
}

// Compose freely
let ui = with_title("Dashboard", login_form)
```

**3. Folding over element trees**

```gleam
// Count all interactive elements
fn count_interactive(elements: List(Element)) -> Int {
  elements
  |> list.flat_map(fn(el) {
    case el {
      Box(_, children) -> [el, ..count_interactive(children)]
      Input(_) -> [el]
      _ -> []
    }
  })
  |> list.length
}
```

**4. Serialization for debugging / testing**

```gleam
fn element_to_string(el: Element) -> String {
  case el {
    Box(styles, children) ->
      "Box(" ++ styles_to_string(styles) ++ ", ["
      ++ list.join(list.map(children, element_to_string), ", ") ++ "])"
    Text(content, _) -> "Text(\"" ++ content ++ "\")"
    Input(opts) -> "Input(" ++ opts_to_string(opts) ++ ")"
    Spacer -> "Spacer"
  }
}
```

**5. Diff-based re-rendering (manual, no reconciler)**

```gleam
fn diff_elements(old: Element, new: Element) -> List(Diff) {
  case old, new {
    Box(old_styles, old_children), Box(new_styles, new_children) ->
      diff_styles(old_styles, new_styles)
      ++ diff_children(old_children, new_children)
    Text(old_content, _), Text(new_content, _) ->
      case old_content == new_content {
        True -> []
        False -> [TextChanged(old_content, new_content)]
      }
    _, _ -> [ElementReplaced(old, new)]
  }
}
```

### Why This Matters for TUIs Specifically

In a web app, an unhandled edge case is a minor UX glitch. In a TUI, it's the user's entire interface freezing with no escape hatch. Functional composability means:

- **State transitions are explicit data transformations** — not scattered `setState` calls across event handlers
- **Every screen is a pure function of state** — `fn render(state: AppState) -> Element` — trivially testable
- **No reconciler overhead** — the element tree is walked once per frame, calling imperative FFI. No virtual DOM diffing, no fiber scheduler
- **Serialization is free** — the element tree is just data. Print it, log it, snapshot it, replay it

---

## Code Generation for Path B (Direct Zig FFI)

If you go with Path B, the three-layer FFI boilerplate is machine-generated. A single script parses `lib.zig` and emits everything:

```bash
# scripts/generate-ffi.sh — run when Zig updates
# Parses packages/core/src/zig/lib.zig and emits:
#   1. src/opentui/ffi_shim.js  (dlopen declarations)
#   2. src/ffi.gleam            (@external declarations)
#   3. src/ffi_auto.gleam       (auto-generated, never hand-edited)
```

The script:
1. Greps `export fn` signatures from `lib.zig`
2. Maps Zig types → FFIType values → generates shim
3. Maps Zig types → Gleam types → generates `@external` declarations
4. Outputs wrapper functions with `Result` error handling

Zero human effort. Run it when Zig updates.

---

## JS Components Are Fully Available

Any JS library works through `@external`:

```gleam
// Markdown
@external(javascript, "marked", "parse")
pub fn parse_markdown(md: String) -> String

// Syntax highlighting
@external(javascript, "tree-sitter-wasm", "parse")
pub fn parse_code(code: String, language: String) -> Tree

// Data formatting
@external(javascript, "yaml", "parse")
pub fn parse_yaml(yaml: String) -> Dynamic

// Physics (OpenTUI has Planck.js / Rapier demos)
@external(javascript, "planck-js", "World")
pub fn create_world(gravity: #(Float, Float)) -> World
```

The ergonomic tax is writing the `@external` declaration. Once written, it's just a function call. For libraries with simple APIs (markdown parsers, syntax highlighters, data formatters), it's trivial. For libraries with complex object-oriented APIs, you'll need wrapper functions in a JS shim.

---

## Updated "What You're Carrying vs Dropping"

### Path A: Wrap `@opentui/core`

| OpenTUI Component | Status | Reason |
|---|---|---|
| `@opentui/core` npm package | ✅ Keep (as dependency) | Handles all Zig FFI, native lib loading, JS API |
| TypeScript bindings (`zig.ts`) | ✅ Used indirectly | Inside `@opentui/core` bundle |
| Zig source | ❌ Don't care | Handled by npm package |
| `@opentui/react` | ❌ Drop | Not relevant |
| `@opentui/solid` | ❌ Drop | Not relevant |
| `packages/web` | ❌ Drop | Not relevant |

### Path B: Direct Zig FFI

| OpenTUI Component | Status | Reason |
|---|---|---|
| `src/zig/` (all .zig files) | ✅ Keep (via submodule) | This is the C API you bind to |
| `build.zig` / `build.zig.zon` | ✅ Keep (via submodule) | Builds the .so/.dylib/.dll |
| `uucode` dependency | ✅ Keep (via submodule) | Pulled in by build.zig.zon |
| TypeScript bindings (`zig.ts`) | ❌ Drop | You replace this with Gleam |
| `@opentui/core` JS bundle | ❌ Drop | You replace this with Gleam |
| `@opentui/react` | ❌ Drop | Not relevant |
| `@opentui/solid` | ❌ Drop | Not relevant |
| `packages/web` | ❌ Drop | Not relevant |

---

## Updated Gotchas

1. **String length**: Zig's C API expects `(ptr, len)` pairs for strings. Gleam strings are UTF-8, but `string.length` returns character count, not byte count. Use `string.byte_size` instead.

2. **`JSCallback` lifetime**: If you bind `setLogCallback` or `setEventCallback`, the `JSCallback` must stay alive or you get a segfault. Store it in a module-level variable, not a local.

3. **`build.zig` output path** (Path B only): The upstream `build.zig` installs to `lib/{target}/` under `packages/core/src/zig/`. If upstream changes the path, update the shim resolver and build script.

4. **Platform detection** (Path B only): The shim maps `process.arch` (`x64`/`arm64`) to Zig target names (`x86_64`/`aarch64`). If Bun ever changes these, update the map.

5. **`@opentui/core` API stability** (Path A only): You're bound to their JS API surface. If they rename `createCliRenderer`, your `@external` breaks. Pin the version in `gleam.toml`.

6. **Gleam `@external` type safety**: The compiler trusts your `@external` declarations. If you declare `fn foo() -> Int` but the JS function returns a string, you get a runtime error. The type system can't verify FFI boundaries.

7. **Async boundary**: Gleam's `Promise` maps to JS Promises, but the ergonomics differ. `@opentui/core`'s `createCliRenderer()` returns a Promise — in Gleam you'll use `use` expressions or `promise.then`.

---

## Where Gleam's Edge Actually Is

For a TUI built on OpenTUI, Gleam's advantage isn't FFI or ecosystem access — it's **correctness guarantees for an environment where crashes are unrecoverable**:

| Guarantee | Why It Matters for TUIs |
|---|---|
| Exhaustive `case` | Missed keybinding = frozen terminal. Compiler prevents this. |
| No null / no undefined | Null deref = dead process. `Result` types force handling. |
| No `any` escape hatch | Can't accidentally bypass the type system. |
| Immutability by default | No accidental state mutation across render cycles. |
| Union types for screen state | Add a screen → compiler tells you every render branch to update. |
| `BitArray` pattern matching | Terminal protocols are byte protocols. Gleam parses them naturally. |
| Pure data element trees | UI as data structures, composable with standard functional patterns. |
| Serialization for free | Element trees print, log, snapshot, replay — no extra work. |

The `@external` tax is a one-time cost per function you use. Once declared, it's just a function call. The correctness guarantees compound with every line of application code you write.

---

## Why Gleam's FP Model Is the Right Fit for TUIs

The raw OpenTUI API is imperative coordinate math:

```ts
buffer.drawText("Login", 0, 0, fg, bg, 0)
buffer.fillRect(0, 2, 40, 1, border)
buffer.drawText("User:", 1, 3, fg, bg, 0)
```

You can't compose that. You can't say "put this inside that." You calculate positions manually. Every change ripples through every coordinate.

Gleam's ADTs fix this by making UI **data instead of side effects**:

```gleam
Box([Padding(2)], [
  Text("Login"),
  Box([Border], [Input([Focused])]),
])
```

Then one `case` expression walks the tree and calls the imperative FFI. That's it. No reconciler, no fiber scheduler, no virtual DOM. Just pattern matching on a tree.

### Why This Matters More for TUIs Than for Web

**1. TUIs are state machines** — discrete screens, modes, focus states. Union types + exhaustive `case` is the natural representation.

| Environment | Missed case consequence |
|---|---|
| Web app | Minor UI glitch, user refreshes page |
| TUI | Frozen terminal, no escape hatch, killed process |

**2. TUI rendering is simple** — a cell buffer, 30-60fps. React's reconciler is overkill for this. A single `case` walk is all you need.

**3. Every transformation is free** — conditional rendering, higher-order wrappers, tree folding, serialization, diffing. All just functions over data. No runtime cost.

### The Real Comparison

The alternative isn't "Gleam vs React." It's:

| Approach | What you write | What happens when layout changes |
|---|---|---|
| Raw imperative | `drawText("Login", x, y, ...)` | Recalculate every coordinate manually |
| React/JSX | `<box><text>Login</text></box>` | Reconciler diffs virtual DOM, patches native |
| Gleam ADT | `Box([], [Text("Login")])` | Single `case` walk calls imperative FFI |

Gleam gets the composability of React's declarative model without the runtime overhead of a reconciler. The element tree is just data — you can map over it, filter it, serialize it, diff it — all pure functions, zero runtime cost.

For anything beyond a single-screen form, the data-driven approach wins.
