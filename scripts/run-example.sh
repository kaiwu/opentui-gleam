#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
EXAMPLES_DIR="$ROOT_DIR/packages/opentui_examples"

example="${1:-catalog}"

case "$example" in
  catalog)
    (cd "$EXAMPLES_DIR" && gleam run)
    ;;
  editor)
    (cd "$EXAMPLES_DIR" && gleam run -m opentui/examples/editor)
    ;;
  terminal-title)
    (cd "$EXAMPLES_DIR" && gleam run -m opentui/examples/terminal_title)
    ;;
  text-wrap)
    (cd "$EXAMPLES_DIR" && gleam run -m opentui/examples/text_wrap)
    ;;
  text-truncation)
    (cd "$EXAMPLES_DIR" && gleam run -m opentui/examples/text_truncation)
    ;;
  list|help|--help|-h)
    cat <<'EOF'
Run OpenTUI Gleam examples from the project root.

Usage:
  ./scripts/run-example.sh <example>

Examples:
  catalog
  editor
  terminal-title
  text-wrap
  text-truncation
EOF
    ;;
  *)
    printf 'Unknown example: %s\n\n' "$example" >&2
    "$0" help >&2
    exit 1
    ;;
esac
