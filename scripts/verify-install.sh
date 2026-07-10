#!/usr/bin/env bash
set -euo pipefail

CODEX_HOME_DIR="${CODEX_HOME:-$HOME/.codex}"
CONFIG="$CODEX_HOME_DIR/config.toml"
FAIL=0

check_agent() {
  local file="$1" expected="$2"
  local path="$CODEX_HOME_DIR/agents/$file"
  if [[ ! -f "$path" ]]; then
    echo "MISSING: $path"
    FAIL=1
    return
  fi
  if ! grep -Eq "^[[:space:]]*model[[:space:]]*=[[:space:]]*\"$expected\"" "$path"; then
    echo "WRONG MODEL: $path (expected $expected)"
    FAIL=1
    return
  fi
  echo "OK: $file -> $expected"
}

check_agent terra-explorer.toml gpt-5.6-terra
check_agent terra-reviewer.toml gpt-5.6-terra
check_agent terra-worker.toml gpt-5.6-terra
check_agent spark-scanner.toml gpt-5.3-codex-spark
check_agent luna-scanner.toml gpt-5.6-luna
check_agent luna-verifier.toml gpt-5.6-luna

if [[ ! -f "$CONFIG" ]]; then
  echo "MISSING: $CONFIG"
  FAIL=1
else
  DEPTH="$(awk '
    /^[[:space:]]*\[agents\][[:space:]]*$/ { in_agents=1; next }
    /^[[:space:]]*\[[^]]+\][[:space:]]*$/ { in_agents=0 }
    in_agents && /^[[:space:]]*max_depth[[:space:]]*=/ {
      line=$0; sub(/^[^=]*=/, "", line); gsub(/[[:space:]]/, "", line); print line; exit
    }
  ' "$CONFIG")"
  if [[ -z "$DEPTH" || "$DEPTH" -lt 2 ]]; then
    echo "INVALID: [agents] max_depth must be >= 2 in $CONFIG"
    FAIL=1
  else
    echo "OK: agents.max_depth=$DEPTH"
  fi
fi

if [[ "$FAIL" -ne 0 ]]; then
  echo ""
  echo "Auto Router setup is incomplete. Run bash ./scripts/install-agents.sh and restart Codex."
  exit 1
fi

echo ""
echo "Installation files are correct. Spark account/session availability is checked at runtime; Luna Scanner is the fallback."
echo "Restart Codex or start a new task before testing @Auto Router."
