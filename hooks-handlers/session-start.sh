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
    "additionalContext": "## Tool Badge\n\nAfter EVERY response where you used tools, render a one-line tool summary as plain text at the very end of your response.\n\n### Categories\nmcp (mcp__* tools, show server name) · file (Read,Write,Edit,Glob,Grep,NotebookEdit) · agent (Task) · sh (Bash) · web (WebSearch,WebFetch) · skill (Skill) · todo (TaskCreate,TaskUpdate,TaskList,TaskGet)\n\n### Format\n╶─ file:Read,Grep · sh:git · mcp:manager-ai ─╴\n\nRules: one line, ╶─ and ─╴ delimiters, category:tools pairs separated by · (middle dot), omit unused categories. Do not wrap in a code block."
  }
}
OUTER_EOF

exit 0
