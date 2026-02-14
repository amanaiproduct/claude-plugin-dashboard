#!/usr/bin/env bash

# Toggle dashboard mode: badge → box → off → badge
# Persists to .claude/dashboard-mode.local in the project root

MODE_FILE=".claude/dashboard-mode.local"

# Ensure .claude directory exists
mkdir -p .claude

# Read current mode
CURRENT="badge"
if [[ -f "$MODE_FILE" ]]; then
  CURRENT=$(head -1 "$MODE_FILE" | tr -d '[:space:]')
fi

# Cycle to next mode
case "$CURRENT" in
  badge) NEXT="box" ;;
  box)   NEXT="off" ;;
  off)   NEXT="badge" ;;
  *)     NEXT="badge" ;;
esac

# Write new mode
echo "$NEXT" > "$MODE_FILE"

echo "Dashboard mode: $CURRENT → $NEXT"
echo "Mode file: $MODE_FILE"
