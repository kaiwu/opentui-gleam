#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

(cd "$ROOT_DIR/packages/opentui_core" && gleam build)
(cd "$ROOT_DIR/packages/opentui_runtime" && gleam build)
(cd "$ROOT_DIR/packages/opentui_examples" && gleam build)
