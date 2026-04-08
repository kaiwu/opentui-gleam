#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

# Build native library from submodule if available (skip if npm prebuilt exists)
if [ -d "$ROOT_DIR/native/opentui-zig" ] && ! [ -d "$ROOT_DIR/packages/opentui_core/node_modules/@opentui" ]; then
  "$ROOT_DIR/scripts/build-native.sh"
fi

(cd "$ROOT_DIR/packages/opentui_core" && gleam build)
(cd "$ROOT_DIR/packages/opentui_runtime" && gleam build)
(cd "$ROOT_DIR/packages/opentui_ui" && gleam build)
(cd "$ROOT_DIR/packages/opentui_3d" && gleam build)
(cd "$ROOT_DIR/packages/opentui_testing" && gleam build)
(cd "$ROOT_DIR/packages/opentui_examples" && gleam build)
