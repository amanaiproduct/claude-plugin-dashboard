---
description: "Toggle dashboard display mode (badge → box → off → badge)"
allowed-tools: ["Bash(${CLAUDE_PLUGIN_ROOT}/scripts/toggle-mode.sh:*)"]
model: "haiku"
---

# Dashboard Toggle

The user wants to cycle the dashboard display mode. Run the toggle script to change the mode and report the result.

```!
"${CLAUDE_PLUGIN_ROOT}/scripts/toggle-mode.sh"
```

After the script runs, tell the user the new mode. Remind them that the change takes effect on the **next session** (since SessionStart hooks run once at session start). Show what each mode looks like:

- **badge**: `╶─ MCP:server · File:Read,Grep ─╴`
- **box**: bordered ASCII box with categories on separate lines
- **off**: no per-turn visualization
