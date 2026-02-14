#!/usr/bin/env bash

# render-dashboard.sh - Full ASCII system map for Claude Code
# Discovers all MCP servers, plugins, agents, skills, and hooks

set -euo pipefail

CLAUDE_DIR="${HOME}/.claude"
PROJECT_CLAUDE_DIR=".claude"
WIDTH=60

# ── Helper functions ─────────────────────────────────────

pad_right() {
  local text="$1"
  local width="$2"
  printf "%-${width}s" "$text"
}

# Print a horizontal line using a box-drawing character
# Note: ─ is 3 bytes / 1 display column, so we use a loop instead of tr
hline() {
  local char="${1:-─}"
  local w="${2:-$WIDTH}"
  local i
  for ((i = 0; i < w; i++)); do
    printf '%s' "$char"
  done
}

# Print a box line with borders
# Compensates for multi-byte Unicode characters that display as single-width
box_line() {
  local content="$1"
  local inner_width=$((WIDTH - 4))
  # Calculate byte length vs character length to find multi-byte overhead
  local byte_len char_len extra_pad
  byte_len=$(printf '%s' "$content" | wc -c | tr -d ' ')
  char_len=$(printf '%s' "$content" | wc -m | tr -d ' ')
  extra_pad=$((byte_len - char_len))
  local pad_width=$((inner_width + extra_pad))
  printf "│  %-${pad_width}s│\n" "$content"
}

# Print a section header
section_header() {
  local title="$1"
  # Use wc -m for character count (not byte count) for proper width calc
  local title_len
  title_len=$(printf '%s' "$title" | wc -m | tr -d ' ')
  local remaining=$((WIDTH - title_len - 5))
  printf "├─ %s " "$title"
  hline "─" "$remaining"
  printf "┤\n"
}

# ── Gather Data ──────────────────────────────────────────

# 1. MCP Servers (from project .mcp.json)
gather_mcp_servers() {
  local mcp_file=".mcp.json"
  if [[ -f "$mcp_file" ]] && command -v jq &>/dev/null; then
    jq -r '.mcpServers | keys[]' "$mcp_file" 2>/dev/null || true
  fi
}

# 2. Installed plugins (from settings.json)
gather_plugins() {
  local settings="${CLAUDE_DIR}/settings.json"
  if [[ -f "$settings" ]] && command -v jq &>/dev/null; then
    jq -r '.enabledPlugins // {} | keys[] | split("@")[0]' "$settings" 2>/dev/null || true
  fi
}

# 3. Project agents (from .claude/agents/)
gather_agents() {
  if [[ -d "${PROJECT_CLAUDE_DIR}/agents" ]]; then
    for f in "${PROJECT_CLAUDE_DIR}/agents"/*.md; do
      [[ -f "$f" ]] && basename "$f" .md
    done
  fi
}

# 4. Project skills (from .claude/skills/)
gather_skills() {
  if [[ -d "${PROJECT_CLAUDE_DIR}/skills" ]]; then
    for d in "${PROJECT_CLAUDE_DIR}/skills"/*/; do
      [[ -d "$d" ]] && basename "$d"
    done
  fi
}

# 5. Active hooks (from plugin cache)
gather_hooks() {
  local plugin_cache="${CLAUDE_DIR}/plugins/cache"
  if [[ -d "$plugin_cache" ]]; then
    find "$plugin_cache" -name "hooks.json" -exec jq -r '.hooks | keys[]' {} \; 2>/dev/null | sort -u || true
  fi
}

# 6. Dashboard mode
get_mode() {
  local mode_file="${PROJECT_CLAUDE_DIR}/dashboard-mode.local"
  if [[ -f "$mode_file" ]]; then
    head -1 "$mode_file" | tr -d '[:space:]'
  else
    echo "badge"
  fi
}

# ── Render Dashboard ─────────────────────────────────────

render() {
  local mode
  mode=$(get_mode)

  # Top border: "┌─ Claude Code System Map " = 26 display chars, fill with ─, then "┐"
  printf "┌─ Claude Code System Map "
  hline "─" $((WIDTH - 26 - 1))
  printf "┐\n"

  # Mode indicator
  box_line "Dashboard mode: ${mode}"
  box_line ""

  # MCP Servers
  section_header "MCP Servers"
  local has_mcp=false
  while IFS= read -r server; do
    [[ -z "$server" ]] && continue
    has_mcp=true
    # Try to get the command from .mcp.json
    local cmd=""
    if command -v jq &>/dev/null && [[ -f ".mcp.json" ]]; then
      cmd=$(jq -r --arg s "$server" '.mcpServers[$s].command // ""' ".mcp.json" 2>/dev/null || true)
    fi
    if [[ -n "$cmd" ]]; then
      box_line "● ${server}  (${cmd})"
    else
      box_line "● ${server}"
    fi
  done < <(gather_mcp_servers)
  if [[ "$has_mcp" == false ]]; then
    box_line "(none detected)"
  fi
  box_line ""

  # Plugins
  section_header "Plugins"
  local has_plugins=false
  while IFS= read -r plugin; do
    [[ -z "$plugin" ]] && continue
    has_plugins=true
    box_line "◆ ${plugin}"
  done < <(gather_plugins)
  if [[ "$has_plugins" == false ]]; then
    box_line "(none installed)"
  fi
  box_line ""

  # Agents
  section_header "Agents"
  local has_agents=false
  while IFS= read -r agent; do
    [[ -z "$agent" ]] && continue
    has_agents=true
    box_line "▸ ${agent}"
  done < <(gather_agents)
  if [[ "$has_agents" == false ]]; then
    box_line "(none in .claude/agents/)"
  fi
  box_line ""

  # Skills
  section_header "Skills"
  local has_skills=false
  while IFS= read -r skill; do
    [[ -z "$skill" ]] && continue
    has_skills=true
    box_line "★ ${skill}"
  done < <(gather_skills)
  if [[ "$has_skills" == false ]]; then
    box_line "(none in .claude/skills/)"
  fi
  box_line ""

  # Hook Events
  section_header "Active Hook Events"
  local has_hooks=false
  while IFS= read -r hook; do
    [[ -z "$hook" ]] && continue
    has_hooks=true
    box_line "⚡ ${hook}"
  done < <(gather_hooks)
  if [[ "$has_hooks" == false ]]; then
    box_line "(none detected)"
  fi

  # Bottom border: "└" = 1 display char, fill, "┘" = 1 display char
  printf "└"
  hline "─" $((WIDTH - 2))
  printf "┘\n"
}

render
