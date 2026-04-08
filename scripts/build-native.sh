#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
ZIG_DIR="$ROOT_DIR/native/opentui-zig/packages/core/src/zig"

if [ ! -d "$ZIG_DIR" ]; then
  echo "Error: native submodule not found at $ZIG_DIR" >&2
  echo "Run: git submodule update --init --recursive" >&2
  exit 1
fi

if ! command -v zig &>/dev/null; then
  echo "Error: zig not found in PATH" >&2
  exit 1
fi

echo "Building native library from submodule..."
(cd "$ZIG_DIR" && zig build -Doptimize=ReleaseFast)
echo "Native library built successfully."
