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
    "additionalContext": "## Plugin Dashboard - Per-Turn Tool Visualization\n\nYou MUST render a tool usage summary at the END of every response where you used at least one tool. Current display mode: **${MODE}**.\n\n### Tool Categorization Rules\nCategorize each tool you used this turn:\n- \`mcp__*\` tools → **MCP** category. Extract server name from the tool name (e.g., \`mcp__manager-ai__list_tasks\` → \`manager-ai: list_tasks\`)\n- \`Read\`, \`Write\`, \`Edit\`, \`Glob\`, \`Grep\`, \`NotebookEdit\` → **File** category\n- \`Task\` → **Agent** category (include the subagent_type if known, e.g., \`Agent:Explore\`)\n- \`Bash\` → **Shell** category\n- \`WebSearch\`, \`WebFetch\` → **Web** category\n- \`Skill\` → **Skill** category\n- \`TaskCreate\`, \`TaskUpdate\`, \`TaskList\`, \`TaskGet\` → **Todo** category\n- All other tools → use the tool name directly\n\n### Badge Mode (current: ${MODE})\nRender the badge by calling a Bash tool with echo -e and ANSI sunset colors at the END of your response. This is the LAST thing you do — after all other text and tool calls.\n\nANSI color codes for each category label (bold):\n- mcp:    \\\\033[1m\\\\033[38;5;209m (coral)\n- file:   \\\\033[1m\\\\033[38;5;180m (tan)\n- agent:  \\\\033[1m\\\\033[38;5;222m (golden)\n- sh:     \\\\033[1m\\\\033[38;5;174m (dusty pink)\n- web:    \\\\033[1m\\\\033[38;5;137m (khaki)\n- skill:  \\\\033[1m\\\\033[38;5;215m (light orange)\n- todo:   \\\\033[1m\\\\033[38;5;180m (wheat)\n\nOther elements:\n- Tool names: \\\\033[38;5;255m (white)\n- Delimiters (╶─ ─╴) and dots (·): \\\\033[38;5;240m (dark gray)\n- Colon after label: \\\\033[38;5;240m (dark gray)\n- Reset: \\\\033[0m\n\nFormat: Build a single echo -e string like this example:\necho -e '\\\\033[38;5;240m╶─\\\\033[0m \\\\033[1m\\\\033[38;5;180mfile\\\\033[0m\\\\033[38;5;240m:\\\\033[38;5;255mRead,Grep\\\\033[0m \\\\033[38;5;240m·\\\\033[0m \\\\033[1m\\\\033[38;5;174msh\\\\033[0m\\\\033[38;5;240m:\\\\033[38;5;255mgit\\\\033[0m \\\\033[38;5;240m─╴\\\\033[0m'\n\nRules:\n- One line only, wrapped in ╶─ and ─╴\n- Category labels bold+colored, tool names white, separators dark gray\n- Colon between category and tools (no space)\n- Categories separated by · (middle dot)\n- For MCP, show server-name:function-list (abbreviate if >3 functions)\n- Omit categories with no tools used\n- The Bash call description should be: Render tool badge\n\n### Box Mode (current: ${MODE})\nRender a bordered ASCII box using double-line borders. PLAIN TEXT ONLY — do NOT use any markdown formatting (no bold, no backticks, no code spans) inside the box. Use this EXACT format:\n\`\`\`\n╔══ tools ═══════════════════════════════╗\n║  mcp    → manager-ai: list, create    ║\n║  file   → Read, Grep, Write           ║\n║  agent  → Explore                     ║\n╚═══════════════════════════════════════╝\n\`\`\`\nRules for box mode:\n- Use double-line box chars: \`╔ ═ ╗ ║ ╚ ╝\`\n- PLAIN TEXT ONLY inside the box — no markdown formatting whatsoever\n- Lowercase category labels (6 chars wide padded), then \`→\`, then tool details\n- One line per category\n- RIGHT BORDER ALIGNMENT IS CRITICAL: every \`║\` on the right must be in the same column. Pad each content line with spaces so all right \`║\` characters align perfectly. Count characters to calculate padding.\n- Consistent box width: pick the width based on the longest content line, then pad ALL lines to that same width\n\n### Important\n- Only render the visualization for the CURRENT mode (${MODE})\n- Place it at the very end of your response, as the LAST tool call or text\n- If no tools were used in a turn (pure text response), do NOT render anything\n- Keep the visualization clean - no extra explanation around it\n- Badge mode: render via Bash echo -e (for ANSI colors)\n- Box mode: render as plain text (not inside a code block)"
  }
}
OUTER_EOF

exit 0
