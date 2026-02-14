---
description: "Show full ASCII system map of all installed plugins, MCP servers, hooks, and tools"
allowed-tools: ["Bash(${CLAUDE_PLUGIN_ROOT}/scripts/render-dashboard.sh:*)"]
---

# Full System Dashboard

The user wants to see a comprehensive ASCII dashboard of their Claude Code setup. Run the render script and display the output exactly as-is (it's pre-formatted ASCII art).

```!
"${CLAUDE_PLUGIN_ROOT}/scripts/render-dashboard.sh"
```

Display the output verbatim. Do not wrap it in a code block — it's already formatted with box-drawing characters.
