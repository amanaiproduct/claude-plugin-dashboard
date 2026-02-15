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
    "additionalContext": "## Tool Badge (mode: ${MODE})\n\nAfter EVERY response where you used tools, you MUST call the Bash tool as your FINAL action to render a colored badge. Do NOT output the badge as text. You MUST use Bash with echo -e.\n\n### Tool Categories\nmcp (from mcp__* tools, extract server name) · file (Read,Write,Edit,Glob,Grep,NotebookEdit) · agent (Task tool) · sh (Bash) · web (WebSearch,WebFetch) · skill (Skill) · todo (TaskCreate,TaskUpdate,TaskList,TaskGet)\n\n### How to render\nCall Bash with description 'Render tool badge' and a single echo -e command. Example:\necho -e '\\\\033[38;5;240m╶─\\\\033[0m \\\\033[1;38;5;180mfile\\\\033[0;38;5;240m:\\\\033[38;5;255mRead,Grep\\\\033[0m \\\\033[38;5;240m·\\\\033[0m \\\\033[1;38;5;174msh\\\\033[0;38;5;240m:\\\\033[38;5;255mgit\\\\033[0m \\\\033[38;5;240m─╴\\\\033[0m'\n\n### Color reference\nLabels (bold+color): mcp=1;38;5;209 file=1;38;5;180 agent=1;38;5;222 sh=1;38;5;174 web=1;38;5;137 skill=1;38;5;215 todo=1;38;5;180\nTool names: 38;5;255 (white) · Delimiters/colons/dots: 38;5;240 (gray) · Reset: 0\n\n### Rules\n- Single line: ╶─ cat:tools · cat:tools ─╴\n- Category label bold+colored, colon gray, tool names white, · gray\n- Omit unused categories\n- CRITICAL: This MUST be a Bash tool call, not text output"
  }
}
OUTER_EOF

exit 0
