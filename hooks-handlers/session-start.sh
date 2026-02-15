#!/usr/bin/env bash

# Dashboard Plugin - SessionStart Hook
# Instructs Claude to render a compact badge directly in the response.
# Uses glyph tags + code spans for stable client-side styling.

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
    "additionalContext": "## Tool Badge\n\nAfter EVERY response where you used tools, render a compact tool badge as the LAST line(s) of your response.\n\n### Categories\nmcp (mcp__* tools, show server name) · file (Read,Write,Edit,Glob,Grep,NotebookEdit) · agent (Task) · sh (Bash) · web (WebSearch,WebFetch) · skill (Skill) · todo (TaskCreate,TaskUpdate,TaskList,TaskGet)\n\n### Badge Mode (current: badge)\nUse compact chips with minimal spacing:\n◆`mcp:manager-ai:list_tasks,create_task` ●`file:read,glob` ▸`sh:git`\n\n### Overflow Rules\n- If badge exceeds ~100 chars OR more than 3 chips, wrap to a second line\n- Second line starts with: ↳\n- Keep each chip intact when wrapping (do not split inside a chip)\n\n### Normalization Rules\n- Lowercase tool names in chips (read, write, glob, grep, websearch)\n- Deduplicate repeated tools in same category\n- Keep order: mcp, file, agent, sh, web, skill, todo\n- No spaces inside code spans\n- Do NOT output [tools: ...] markers\n- Do NOT call Bash to render badges\n- If no tools were used, output no badge"
  }
}
OUTER_EOF

exit 0
