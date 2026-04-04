#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

(cd "$ROOT_DIR/packages/opentui_core" && gleam test)
(cd "$ROOT_DIR/packages/opentui_runtime" && gleam test)
(cd "$ROOT_DIR/packages/opentui_ui" && gleam test)
(cd "$ROOT_DIR/packages/opentui_examples" && gleam test)
