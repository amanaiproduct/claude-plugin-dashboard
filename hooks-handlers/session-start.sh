#!/usr/bin/env bash

# Dashboard Plugin - SessionStart Hook
# Reads the current display mode and injects rendering instructions into the session.
# Theme: Sunset (warm ambers, coral, peach)

# Determine project root (where .claude/ lives)
# Try common locations for the mode file
MODE="badge"
for candidate in \
  ".claude/dashboard-mode.local" \
  "${HOME}/.claude/dashboard-mode.local"; do
  if [[ -f "$candidate" ]]; then
    MODE=$(head -1 "$candidate" | tr -d '[:space:]')
    break
  fi
done

# Validate mode
case "$MODE" in
  badge|box|off) ;;
  *) MODE="badge" ;;
esac

# If mode is "off", inject minimal context so Claude knows the plugin exists but doesn't render
if [[ "$MODE" == "off" ]]; then
  cat << 'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": "The plugin-dashboard plugin is installed but currently set to 'off' mode. No per-turn tool visualization should be rendered. The user can run /dashboard-toggle to re-enable it."
  }
}
EOF
  exit 0
fi

# Build the additionalContext with rendering instructions
# Using a here-doc with variable interpolation for the mode
cat << OUTER_EOF
{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": "## Plugin Dashboard - Per-Turn Tool Visualization\n\nYou MUST render a tool usage summary at the END of every response where you used at least one tool. Current display mode: **${MODE}**.\n\n### Tool Categorization Rules\nCategorize each tool you used this turn:\n- \`mcp__*\` tools → **MCP** category. Extract server name from the tool name (e.g., \`mcp__manager-ai__list_tasks\` → \`manager-ai: list_tasks\`)\n- \`Read\`, \`Write\`, \`Edit\`, \`Glob\`, \`Grep\`, \`NotebookEdit\` → **File** category\n- \`Task\` → **Agent** category (include the subagent_type if known, e.g., \`Agent:Explore\`)\n- \`Bash\` → **Shell** category\n- \`WebSearch\`, \`WebFetch\` → **Web** category\n- \`Skill\` → **Skill** category\n- \`TaskCreate\`, \`TaskUpdate\`, \`TaskList\`, \`TaskGet\` → **Todo** category\n- All other tools → use the tool name directly\n\n### Badge Mode (current: ${MODE})\nRender a single compact line. Group tools by category, separate with \` · \`. Use this format:\n\`\`\`\n╶─ mcp:manager-ai · file:Read,Grep · sh:git ─╴\n\`\`\`\nRules for badge mode:\n- One line only, wrapped in \`╶─\` and \`─╴\` delimiters\n- Lowercase category labels: mcp, file, agent, sh, web, skill, todo\n- Category:tool-list format, categories separated by \` · \`\n- For MCP, show server-name:function-list (abbreviate if >3 functions)\n- Omit categories with no tools used\n\n### Box Mode (current: ${MODE})\nRender a bordered ASCII box using double-line borders. PLAIN TEXT ONLY — do NOT use any markdown formatting (no bold, no backticks, no code spans) inside the box. Use this EXACT format:\n\`\`\`\n╔══ tools ═══════════════════════════════╗\n║  mcp    → manager-ai: list, create    ║\n║  file   → Read, Grep, Write           ║\n║  agent  → Explore                     ║\n╚═══════════════════════════════════════╝\n\`\`\`\nRules for box mode:\n- Use double-line box chars: \`╔ ═ ╗ ║ ╚ ╝\`\n- PLAIN TEXT ONLY inside the box — no markdown formatting whatsoever\n- Lowercase category labels (6 chars wide padded), then \`→\`, then tool details\n- One line per category\n- RIGHT BORDER ALIGNMENT IS CRITICAL: every \`║\` on the right must be in the same column. Pad each content line with spaces so all right \`║\` characters align perfectly. Count characters to calculate padding.\n- Consistent box width: pick the width based on the longest content line, then pad ALL lines to that same width\n\n### Important\n- Only render the visualization for the CURRENT mode (${MODE})\n- Place it at the very end of your response, after all other content\n- If no tools were used in a turn (pure text response), do NOT render anything\n- Keep the visualization clean - no extra explanation around it\n- The dashboard line/box should be rendered as plain text (not inside a code block)"
  }
}
OUTER_EOF

exit 0
