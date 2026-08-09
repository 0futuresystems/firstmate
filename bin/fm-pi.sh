#!/usr/bin/env bash
# Launch a Firstmate primary under Pi with its tracked project extensions.
#
# Usage: fm-pi.sh [Pi options and prompts...]
# Set FM_PI_HARNESS=pi-signed to select the signed wrapper; pi is the default.
# The extension paths are absolute so the primary may keep any project cwd.
set -eu

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FM_ROOT="${FM_ROOT_OVERRIDE:-$(cd "$SCRIPT_DIR/.." && pwd)}"
HARNESS=${FM_PI_HARNESS:-pi}

case "$HARNESS" in
  pi|pi-signed) ;;
  *)
    printf 'fm-pi.sh: FM_PI_HARNESS must be pi or pi-signed, got %s\n' "$HARNESS" >&2
    exit 2
    ;;
esac

command -v "$HARNESS" >/dev/null 2>&1 || {
  printf 'fm-pi.sh: %s is not available on PATH\n' "$HARNESS" >&2
  exit 127
}

exec env FM_PI_HARNESS="$HARNESS" "$HARNESS" \
  --no-extensions \
  -e "$FM_ROOT/.pi/extensions/fm-calm.ts" \
  -e "$FM_ROOT/.pi/extensions/fm-primary-pi-watch.ts" \
  -e "$FM_ROOT/.pi/extensions/fm-primary-turnend-guard.ts" \
  "$@"
