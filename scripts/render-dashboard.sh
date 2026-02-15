#!/usr/bin/env bash

# render-dashboard.sh - Full ASCII system map for Claude Code
# Uses double-line box-drawing with ANSI sunset color theme
# (ANSI codes render in Claude Code Bash tool output)

set -euo pipefail

# Find project root (look for .mcp.json or .git in current dir or parents)
find_project_root() {
  local dir="$PWD"
  while [[ "$dir" != "/" ]]; do
    if [[ -f "$dir/.mcp.json" ]] || [[ -d "$dir/.git" && -d "$dir/.claude" ]]; then
      echo "$dir"
      return
    fi
    dir=$(dirname "$dir")
  done
  echo "$PWD"
}

PROJECT_ROOT=$(find_project_root)
cd "$PROJECT_ROOT"

CLAUDE_DIR="${HOME}/.claude"
PROJECT_CLAUDE_DIR=".claude"
WIDTH=58

# ── Sunset Theme Colors ────────────────────────────────
RST='\033[0m'
BOLD='\033[1m'
DIM='\033[2m'

BORDER='\033[38;5;173m'    # terracotta (box borders)
HEADER='\033[38;5;216m'    # peach (section titles)
ACCENT='\033[38;5;180m'    # wheat (metadata labels)

C_MCP='\033[38;5;209m'     # coral
C_FILE='\033[38;5;180m'    # tan
C_AGENT='\033[38;5;222m'   # golden
C_SKILL='\033[38;5;215m'   # light orange
C_HOOK='\033[38;5;174m'    # dusty pink

WHITE='\033[38;5;255m'
GRAY='\033[38;5;245m'
DARKGRAY='\033[38;5;240m'

# ── Helper functions ────────────────────────────────────

# Print N copies of a character
repeat_char() {
  local char="$1" n="$2"
  for ((i = 0; i < n; i++)); do printf '%s' "$char"; done
}

# Print a box line with double-line borders and proper padding
# Strips ANSI codes for width calculation but preserves them in output
box_line() {
  local content="$1"
  local inner=$((WIDTH - 4))  # "║  " (3) + "║" (1)
  # Strip ANSI codes for visible width calculation
  local stripped
  stripped=$(printf '%b' "$content" | sed 's/\x1b\[[0-9;]*m//g')
  local visible_len=${#stripped}
  local pad=$((inner - visible_len))
  ((pad < 0)) && pad=0
  printf "${BORDER}║${RST}  %b%*s${BORDER}║${RST}\n" "$content" "$pad" ""
}

# Print a tree item (├─ or └─) with colors
tree_item() {
  local connector="$1" name="$2" detail="${3:-}" color="${4:-$WHITE}"
  if [[ -n "$detail" ]]; then
    local gap=$((22 - ${#name}))
    ((gap < 1)) && gap=1
    box_line "${DARKGRAY}${connector}${RST} ${color}${name}${RST}$(printf '%*s' "$gap" '')${GRAY}${detail}${RST}"
  else
    box_line "${DARKGRAY}${connector}${RST} ${color}${name}${RST}"
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
  local fill=$((WIDTH - title_len - 6))
  printf "${BORDER}╔══${RST} ${HEADER}${BOLD}%s${RST} ${BORDER}" "$title"
  repeat_char "═" "$fill"
  printf '╗\n'

  # Summary stats
  box_line ""
  box_line "${ACCENT}mode${RST} ${WHITE}${mode}${RST}  ${DARKGRAY}·${RST}  ${ACCENT}plugins${RST} ${WHITE}${n_plugins}${RST}  ${DARKGRAY}·${RST}  ${ACCENT}hooks${RST} ${WHITE}${n_hooks}${RST}"
  box_line ""

  # MCP Servers
  box_line "${C_MCP}${BOLD}mcp servers${RST}"
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
    box_line "  ${DARKGRAY}(none detected)${RST}"
  else
    for ((i = 0; i < ${#items[@]}; i++)); do
      local name="${items[$i]%%|*}" detail="${items[$i]#*|}"
      local conn="├─"
      ((i == ${#items[@]} - 1)) && conn="└─"
      tree_item "$conn" "$name" "$detail" "$WHITE"
    done
  fi
  box_line ""

  # Plugins
  box_line "${C_FILE}${BOLD}plugins${RST}"
  items=()
  while IFS= read -r plugin; do
    [[ -z "$plugin" ]] && continue
    items+=("$plugin")
  done < <(gather_plugins)
  if [[ ${#items[@]} -eq 0 ]]; then
    box_line "  ${DARKGRAY}(none installed)${RST}"
  else
    for ((i = 0; i < ${#items[@]}; i++)); do
      local conn="├─"
      ((i == ${#items[@]} - 1)) && conn="└─"
      tree_item "$conn" "${items[$i]}" "" "$WHITE"
    done
  fi
  box_line ""

  # Agents
  box_line "${C_AGENT}${BOLD}agents${RST}"
  items=()
  while IFS= read -r agent; do
    [[ -z "$agent" ]] && continue
    items+=("$agent")
  done < <(gather_agents)
  if [[ ${#items[@]} -eq 0 ]]; then
    box_line "  ${DARKGRAY}(none in .claude/agents/)${RST}"
  else
    for ((i = 0; i < ${#items[@]}; i++)); do
      local conn="├─"
      ((i == ${#items[@]} - 1)) && conn="└─"
      tree_item "$conn" "${items[$i]}" "" "$WHITE"
    done
  fi
  box_line ""

  # Skills
  box_line "${C_SKILL}${BOLD}skills${RST}"
  items=()
  while IFS= read -r skill; do
    [[ -z "$skill" ]] && continue
    items+=("$skill")
  done < <(gather_skills)
  if [[ ${#items[@]} -eq 0 ]]; then
    box_line "  ${DARKGRAY}(none in .claude/skills/)${RST}"
  else
    for ((i = 0; i < ${#items[@]}; i++)); do
      local conn="├─"
      ((i == ${#items[@]} - 1)) && conn="└─"
      tree_item "$conn" "${items[$i]}" "" "$WHITE"
    done
  fi
  box_line ""

  # Hooks
  box_line "${C_HOOK}${BOLD}hooks${RST}"
  items=()
  while IFS= read -r hook; do
    [[ -z "$hook" ]] && continue
    items+=("$hook")
  done < <(gather_hooks)
  if [[ ${#items[@]} -eq 0 ]]; then
    box_line "  (none detected)"
  else
    for ((i = 0; i < ${#items[@]}; i++)); do
      local conn="├─"
      ((i == ${#items[@]} - 1)) && conn="└─"
      tree_item "$conn" "${items[$i]}" "" "$WHITE"
    done
  fi
  box_line ""

  # Bottom border
  printf "${BORDER}╚"
  repeat_char "═" $((WIDTH - 2))
  printf '╝\n'
  printf "${RST}"
}

render
