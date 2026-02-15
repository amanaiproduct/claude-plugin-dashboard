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
    "additionalContext": "## Tool Badge\n\nAfter EVERY response where you used tools, output a tool marker as the LAST line of your response. A Stop hook will pick it up and render a colored badge.\n\n### Categories\nmcp (mcp__* tools, show server name) · file (Read,Write,Edit,Glob,Grep,NotebookEdit) · agent (Task) · sh (Bash) · web (WebSearch,WebFetch) · skill (Skill) · todo (TaskCreate,TaskUpdate,TaskList,TaskGet)\n\n### Format\nOutput this exact pattern as your last line:\n[tools: category:tools category:tools]\n\nExample: [tools: file:Read,Grep sh:git mcp:manager-ai]\n\nRules:\n- Space-separated category:tools pairs inside [tools: ...]\n- Omit unused categories\n- This marker will be processed by a Stop hook that renders sunset ANSI colors"
  }
}
OUTER_EOF

exit 0
