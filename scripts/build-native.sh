#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
ZIG_DIR="$ROOT_DIR/native/opentui-zig/packages/core/src/zig"

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
TARGET_OUTPUT_DIR="$ZIG_DIR/lib/$TARGET"

echo "Building OpenTUI native library for $TARGET..."

cd "$ZIG_DIR"

# Build the native library
zig build -Doptimize=ReleaseSafe

if [ -d "$TARGET_OUTPUT_DIR" ]; then
  echo "Native library available at $TARGET_OUTPUT_DIR"
elif [ -d "$ZIG_DIR/zig-out/lib" ]; then
  echo "Native library available at $ZIG_DIR/zig-out/lib"
else
  echo "Warning: Could not find built library output directory"
fi
