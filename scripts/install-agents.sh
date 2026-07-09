#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEST="${CODEX_HOME:-$HOME/.codex}/agents"
STAMP="$(date +%Y%m%d%H%M%S)"

mkdir -p "$DEST"

for src in "$ROOT"/agents/*.toml; do
  dst="$DEST/$(basename "$src")"
  if [[ -e "$dst" ]]; then
    cp "$dst" "$dst.bak.$STAMP"
  fi
  cp "$src" "$dst"
  echo "Installed: $dst"
done

printf '\nCustom agents installed. Restart Codex or start a new task.\n'
