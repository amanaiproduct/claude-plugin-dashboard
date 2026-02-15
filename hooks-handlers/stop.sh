#!/usr/bin/env bash

# Stop hook - renders colored tool badge to stderr after Claude's response
# Parses the response for a tool marker pattern and renders with ANSI sunset colors

# Read stdin (the hook input JSON)
INPUT=$(cat)

# Extract the assistant's response text
RESPONSE=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    # Try different possible paths for the response content
    resp = data.get('stop_response', data.get('response', data.get('content', '')))
    if isinstance(resp, list):
        resp = ' '.join(str(r) for r in resp)
    print(resp)
except:
    print('')
" 2>/dev/null)

# Extract tool list from [tools: ...] marker using python
TOOL_LIST=$(echo "$RESPONSE" | python3 -c "
import sys, re
text = sys.stdin.read()
m = re.search(r'\[tools:\s*([^\]]+)\]', text)
print(m.group(1).strip() if m else '')
" 2>/dev/null)

if [[ -z "$TOOL_LIST" ]]; then
  echo '{"hookSpecificOutput":{}}'
  exit 0
fi

# Render colored badge to stderr
RST='\033[0m'
GRAY='\033[38;5;240m'
WHITE='\033[38;5;255m'

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

# Parse space-separated category:tools pairs
parts=()
for pair in $TOOL_LIST; do
  cat="${pair%%:*}"
  tools="${pair#*:}"
  c=$(color_for "$cat")
  parts+=("${c}${cat}${RST}${GRAY}:${WHITE}${tools}${RST}")
done

# Join with gray middle dot
result=""
for ((i=0; i<${#parts[@]}; i++)); do
  ((i > 0)) && result+="${GRAY} · ${RST}"
  result+="${parts[$i]}"
done

# Output to stderr (might pass through to terminal)
echo -e "${GRAY}╶─${RST} ${result} ${GRAY}─╴${RST}" >&2

# Output valid JSON to stdout
echo '{"hookSpecificOutput":{}}'
