#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
EXAMPLES_DIR="$ROOT_DIR/packages/opentui_examples"

example="${1:-catalog}"

run_module() {
  local module="$1"
  (cd "$EXAMPLES_DIR" && gleam run -m "$module")
}

case "$example" in
  catalog)
    (cd "$EXAMPLES_DIR" && gleam run)
    ;;
  editor)
    run_module "opentui/examples/editor"
    ;;
  editor-demo)
    run_module "opentui/examples/editor"
    ;;
  terminal-title)
    run_module "opentui/examples/terminal_title"
    ;;
  text-wrap)
    run_module "opentui/examples/text_wrap"
    ;;
  text-truncation)
    run_module "opentui/examples/text_truncation"
    ;;
  text-truncation-demo)
    run_module "opentui/examples/text_truncation"
    ;;
  list|help|--help|-h)
    cat <<'EOF'
Run OpenTUI Gleam examples from the project root.

Usage:
  ./scripts/run-example.sh <example>

Examples:
  catalog
  editor
  editor-demo
  terminal-title
  text-wrap
  text-truncation
  text-truncation-demo

Any catalog id shown by `./scripts/run-example.sh catalog` is also accepted.
EOF
    ;;
  *)
    module="opentui/examples/${example//-/_}"
    candidate="$EXAMPLES_DIR/src/opentui/examples/${example//-/_}.gleam"
    if [ -f "$candidate" ]; then
      run_module "$module"
    else
      printf 'Unknown example: %s\n\n' "$example" >&2
      "$0" help >&2
      exit 1
    fi
    ;;
esac
