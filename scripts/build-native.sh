#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
ZIG_DIR="$ROOT_DIR/native/opentui-zig/packages/core/src/zig"
OUTPUT_DIR="$ROOT_DIR/priv/lib"

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

# Copy the output to priv/lib
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
