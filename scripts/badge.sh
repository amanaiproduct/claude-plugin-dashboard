#!/usr/bin/env bash
# Render a sunset-colored tool badge
# Usage: badge.sh "file:Read,Grep" "sh:git" "mcp:manager-ai"

RST='\033[0m'
GRAY='\033[38;5;240m'
WHITE='\033[38;5;255m'

# Category color map (bold + color)
color_for() {
  case "$1" in
    mcp)   echo '\033[1;38;5;209m' ;;
    file)  echo '\033[1;38;5;180m' ;;
    agent) echo '\033[1;38;5;222m' ;;
    sh)    echo '\033[1;38;5;174m' ;;
    web)   echo '\033[1;38;5;137m' ;;
    skill) echo '\033[1;38;5;215m' ;;
    todo)  echo '\033[1;38;5;180m' ;;
    *)     echo '\033[1;38;5;255m' ;;
  esac
}

parts=()
for arg in "$@"; do
  cat="${arg%%:*}"
  tools="${arg#*:}"
  c=$(color_for "$cat")
  parts+=("${c}${cat}${RST}${GRAY}:${WHITE}${tools}${RST}")
done

# Join with gray middle dot
sep="${GRAY} · ${RST}"
result=""
for ((i=0; i<${#parts[@]}; i++)); do
  ((i > 0)) && result+="$sep"
  result+="${parts[$i]}"
done

echo -e "${GRAY}╶─${RST} ${result} ${GRAY}─╴${RST}"
