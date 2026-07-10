#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CODEX_HOME_DIR="${CODEX_HOME:-$HOME/.codex}"
DEST="$CODEX_HOME_DIR/agents"
CONFIG="$CODEX_HOME_DIR/config.toml"
STAMP="$(date +%Y%m%d%H%M%S)"

mkdir -p "$DEST" "$CODEX_HOME_DIR"

for src in "$ROOT"/agents/*.toml; do
  dst="$DEST/$(basename "$src")"
  if [[ -e "$dst" ]]; then
    cp "$dst" "$dst.bak.$STAMP"
  fi
  cp "$src" "$dst"
  echo "Installed: $dst"
done

if [[ -e "$CONFIG" ]]; then
  cp "$CONFIG" "$CONFIG.bak.$STAMP"
else
  : > "$CONFIG"
fi

TMP="$(mktemp)"
awk '
BEGIN {
  in_agents = 0
  seen_agents = 0
  seen_depth = 0
  seen_threads = 0
}
function emit_missing() {
  if (!seen_threads) print "max_threads = 6"
  if (!seen_depth) print "max_depth = 2"
}
{
  if ($0 ~ /^[[:space:]]*\[[^]]+\][[:space:]]*$/) {
    if (in_agents) emit_missing()
    if ($0 ~ /^[[:space:]]*\[agents\][[:space:]]*$/) {
      in_agents = 1
      seen_agents = 1
      seen_depth = 0
      seen_threads = 0
      print
      next
    }
    in_agents = 0
    print
    next
  }

  if (in_agents && $0 ~ /^[[:space:]]*max_depth[[:space:]]*=/) {
    line = $0
    sub(/^[^=]*=/, "", line)
    gsub(/[[:space:]]/, "", line)
    if ((line + 0) < 2) print "max_depth = 2"
    else print
    seen_depth = 1
    next
  }

  if (in_agents && $0 ~ /^[[:space:]]*max_threads[[:space:]]*=/) {
    seen_threads = 1
    print
    next
  }

  print
}
END {
  if (in_agents) emit_missing()
  if (!seen_agents) {
    print ""
    print "[agents]"
    print "max_threads = 6"
    print "max_depth = 2"
  }
}
' "$CONFIG" > "$TMP"
mv "$TMP" "$CONFIG"

printf '\nConfigured nested custom agents in: %s\n' "$CONFIG"
printf 'Required: [agents] max_depth >= 2\n'
printf 'Restart the ChatGPT desktop app or start a new Codex task so the custom-agent registry reloads.\n'
printf 'Then run: bash ./scripts/verify-install.sh\n'
