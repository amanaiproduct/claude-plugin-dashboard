#!/usr/bin/env bash

# Dashboard Plugin - SessionStart Hook
# Injects per-turn tool badge rendering instructions.
# Theme: Sunset (ANSI 256-color via Bash echo -e)

MODE="badge"
for candidate in \
  ".claude/dashboard-mode.local" \
  "${HOME}/.claude/dashboard-mode.local"; do
  if [[ -f "$candidate" ]]; then
    MODE=$(head -1 "$candidate" | tr -d '[:space:]')
    break
  fi
done

case "$MODE" in
  badge|box|off) ;;
  *) MODE="badge" ;;
esac

if [[ "$MODE" == "off" ]]; then
  cat << 'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": "Plugin-dashboard is off. Run /dashboard-toggle to re-enable."
  }
}
EOF
  exit 0
fi

# Build compact instructions
cat << OUTER_EOF
{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": "## Tool Badge\n\nAfter EVERY response where you used tools, your FINAL action MUST be calling the badge script via Bash. Never output the badge as text.\n\n### Categories\nmcp (mcp__* tools) · file (Read,Write,Edit,Glob,Grep,NotebookEdit) · agent (Task) · sh (Bash) · web (WebSearch,WebFetch) · skill (Skill) · todo (TaskCreate,TaskUpdate,TaskList,TaskGet)\n\n### MANDATORY: Call this as your last Bash action\nRun: ${CLAUDE_PLUGIN_ROOT}/scripts/badge.sh with quoted args for each category used.\nExample for file+shell tools: ${CLAUDE_PLUGIN_ROOT}/scripts/badge.sh 'file:Read,Grep' 'sh:git status'\nExample for all three: ${CLAUDE_PLUGIN_ROOT}/scripts/badge.sh 'file:Read' 'sh:git' 'mcp:manager-ai'\nOutput: ╶─ file:Read,Grep · sh:git · mcp:manager-ai ─╴ (with sunset ANSI colors)\nOmit categories not used this turn. Bash description: Render tool badge"
  }
}
OUTER_EOF

exit 0
