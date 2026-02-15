#!/usr/bin/env bash

# render-dashboard.sh - Full ASCII system map for Claude Code
# Theme: Sunset (warm ambers, coral, peach)
# Discovers all MCP servers, plugins, agents, skills, and hooks

set -euo pipefail

CLAUDE_DIR="${HOME}/.claude"
PROJECT_CLAUDE_DIR=".claude"
WIDTH=58

# ── Sunset Color Palette ────────────────────────────────

RST=$'\033[0m'
BOLD=$'\033[1m'

BORDER=$'\033[38;5;173m'    # terracotta
HEADER=$'\033[38;5;216m'    # peach
ACCENT=$'\033[38;5;180m'    # wheat

C_MCP=$'\033[38;5;209m'     # coral
C_PLUGIN=$'\033[38;5;180m'  # tan
C_AGENT=$'\033[38;5;222m'   # golden
C_SKILL=$'\033[38;5;215m'   # light orange
C_HOOK=$'\033[38;5;174m'    # dusty pink

WHITE=$'\033[38;5;255m'
DARKGRAY=$'\033[38;5;240m'

# ── Helper functions ────────────────────────────────────

# Strip ANSI escape sequences for display-width measurement
strip_ansi() {
  printf '%s' "$1" | sed $'s/\033\\[[0-9;]*m//g'
}

# Get visible character count (excluding ANSI codes)
visible_len() {
  local stripped
  stripped=$(strip_ansi "$1")
  printf '%s' "$stripped" | wc -m | tr -d ' '
}

# Print N copies of a character
repeat_char() {
  local char="$1" n="$2"
  for ((i = 0; i < n; i++)); do printf '%s' "$char"; done
}

# Print a box line with colored borders and proper padding
box_line() {
  local content="$1"
  local inner=$((WIDTH - 4))  # "║  " (3) + "║" (1)
  local vis
  vis=$(visible_len "$content")
  local pad=$((inner - vis))
  ((pad < 0)) && pad=0
  local spaces
  printf -v spaces '%*s' "$pad" ""
  printf '%b  %s%s%b\n' "${BORDER}║${RST}" "$content" "$spaces" "${BORDER}║${RST}"
}

# Print a section header with colored label
section_header() {
  local color="$1" title="$2"
  local prefix="${BORDER}║${RST}  ${color}${BOLD}${title}${RST}"
  box_line "${color}${BOLD}${title}${RST}"
}

# Print a tree item (├─ or └─)
tree_item() {
  local connector="$1" name="$2" detail="${3:-}"
  if [[ -n "$detail" ]]; then
    box_line "${DARKGRAY}${connector}${RST} ${WHITE}${name}${RST}$(printf '%*s' $((22 - ${#name})) '')${DARKGRAY}${detail}${RST}"
  else
    box_line "${DARKGRAY}${connector}${RST} ${WHITE}${name}${RST}"
  fi
}

# ── Gather Data ─────────────────────────────────────────

gather_mcp_servers() {
  local mcp_file=".mcp.json"
  if [[ -f "$mcp_file" ]] && command -v jq &>/dev/null; then
    jq -r '.mcpServers | keys[]' "$mcp_file" 2>/dev/null || true
  fi
}

gather_plugins() {
  local settings="${CLAUDE_DIR}/settings.json"
  if [[ -f "$settings" ]] && command -v jq &>/dev/null; then
    jq -r '.enabledPlugins // {} | keys[] | split("@")[0]' "$settings" 2>/dev/null || true
  fi
}

gather_agents() {
  if [[ -d "${PROJECT_CLAUDE_DIR}/agents" ]]; then
    for f in "${PROJECT_CLAUDE_DIR}/agents"/*.md; do
      [[ -f "$f" ]] && basename "$f" .md
    done
  fi
}

gather_skills() {
  if [[ -d "${PROJECT_CLAUDE_DIR}/skills" ]]; then
    for d in "${PROJECT_CLAUDE_DIR}/skills"/*/; do
      [[ -d "$d" ]] && basename "$d"
    done
  fi
}

gather_hooks() {
  local plugin_cache="${CLAUDE_DIR}/plugins/cache"
  if [[ -d "$plugin_cache" ]]; then
    find "$plugin_cache" -name "hooks.json" -exec jq -r '.hooks | keys[]' {} \; 2>/dev/null | sort -u || true
  fi
}

get_mode() {
  local mode_file="${PROJECT_CLAUDE_DIR}/dashboard-mode.local"
  if [[ -f "$mode_file" ]]; then
    head -1 "$mode_file" | tr -d '[:space:]'
  else
    echo "badge"
  fi
}

# ── Render ──────────────────────────────────────────────

render() {
  local mode
  mode=$(get_mode)

  # Count items for summary line
  local n_plugins=0 n_hooks=0
  while IFS= read -r _; do ((n_plugins++)); done < <(gather_plugins)
  while IFS= read -r _; do ((n_hooks++)); done < <(gather_hooks)

  # Top border
  local title="Claude Code System Map"
  local title_len=${#title}
  local fill=$((WIDTH - title_len - 6))  # "╔══ " (4) + " ╗" (2)
  printf '%b' "${BORDER}╔══${RST} ${HEADER}${BOLD}${title}${RST} ${BORDER}"
  repeat_char "═" "$fill"
  printf '%b\n' "╗${RST}"

  # Summary stats
  box_line ""
  box_line "${ACCENT}mode${RST} ${WHITE}${mode}${RST}  ${DARKGRAY}·${RST}  ${ACCENT}plugins${RST} ${WHITE}${n_plugins}${RST}  ${DARKGRAY}·${RST}  ${ACCENT}hooks${RST} ${WHITE}${n_hooks}${RST}"
  box_line ""

  # MCP Servers
  section_header "$C_MCP" "mcp servers"
  local items=()
  while IFS= read -r server; do
    [[ -z "$server" ]] && continue
    local cmd=""
    if command -v jq &>/dev/null && [[ -f ".mcp.json" ]]; then
      cmd=$(jq -r --arg s "$server" '.mcpServers[$s].command // ""' ".mcp.json" 2>/dev/null || true)
    fi
    items+=("${server}|${cmd}")
  done < <(gather_mcp_servers)
  if [[ ${#items[@]} -eq 0 ]]; then
    box_line "${DARKGRAY}(none detected)${RST}"
  else
    for ((i = 0; i < ${#items[@]}; i++)); do
      local name="${items[$i]%%|*}" detail="${items[$i]#*|}"
      local conn="├─"
      ((i == ${#items[@]} - 1)) && conn="└─"
      tree_item "$conn" "$name" "$detail"
    done
  fi
  box_line ""

  # Plugins
  section_header "$C_PLUGIN" "plugins"
  items=()
  while IFS= read -r plugin; do
    [[ -z "$plugin" ]] && continue
    items+=("$plugin")
  done < <(gather_plugins)
  if [[ ${#items[@]} -eq 0 ]]; then
    box_line "${DARKGRAY}(none installed)${RST}"
  else
    for ((i = 0; i < ${#items[@]}; i++)); do
      local conn="├─"
      ((i == ${#items[@]} - 1)) && conn="└─"
      tree_item "$conn" "${items[$i]}"
    done
  fi
  box_line ""

  # Agents
  section_header "$C_AGENT" "agents"
  items=()
  while IFS= read -r agent; do
    [[ -z "$agent" ]] && continue
    items+=("$agent")
  done < <(gather_agents)
  if [[ ${#items[@]} -eq 0 ]]; then
    box_line "${DARKGRAY}(none in .claude/agents/)${RST}"
  else
    for ((i = 0; i < ${#items[@]}; i++)); do
      local conn="├─"
      ((i == ${#items[@]} - 1)) && conn="└─"
      tree_item "$conn" "${items[$i]}"
    done
  fi
  box_line ""

  # Skills
  section_header "$C_SKILL" "skills"
  items=()
  while IFS= read -r skill; do
    [[ -z "$skill" ]] && continue
    items+=("$skill")
  done < <(gather_skills)
  if [[ ${#items[@]} -eq 0 ]]; then
    box_line "${DARKGRAY}(none in .claude/skills/)${RST}"
  else
    for ((i = 0; i < ${#items[@]}; i++)); do
      local conn="├─"
      ((i == ${#items[@]} - 1)) && conn="└─"
      tree_item "$conn" "${items[$i]}"
    done
  fi
  box_line ""

  # Hooks
  section_header "$C_HOOK" "hooks"
  items=()
  while IFS= read -r hook; do
    [[ -z "$hook" ]] && continue
    items+=("$hook")
  done < <(gather_hooks)
  if [[ ${#items[@]} -eq 0 ]]; then
    box_line "${DARKGRAY}(none detected)${RST}"
  else
    for ((i = 0; i < ${#items[@]}; i++)); do
      local conn="├─"
      ((i == ${#items[@]} - 1)) && conn="└─"
      tree_item "$conn" "${items[$i]}"
    done
  fi
  box_line ""

  # Bottom border
  printf '%b' "${BORDER}╚"
  repeat_char "═" $((WIDTH - 2))
  printf '%b\n' "╝${RST}"
}

render
