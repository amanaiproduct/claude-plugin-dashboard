# Plugin Dashboard for Claude Code

A per-turn tool usage visualizer for Claude Code. Shows which tools (MCP servers, file ops, agents, shell commands) were used on every turn, rendered as a compact badge or bordered ASCII box.

## Install

```bash
claude plugin add github:amank94/claude-plugin-dashboard
```

## What it does

Every time Claude uses a tool, a summary is appended to the response:

**Badge mode** (default)
```
╶─ MCP:manager-ai · File:Read,Grep · Agent:Explore ─╴
```

**Box mode**
```
┌─ This Turn ─────────────────────────┐
│  MCP   manager-ai: list_tasks       │
│  File  Read, Grep                   │
│  Agent Explore                      │
└─────────────────────────────────────┘
```

**Off mode** - no visualization (plugin stays installed but silent)

## Commands

| Command | Description |
|---------|-------------|
| `/dashboard-toggle` | Cycle display mode: badge -> box -> off -> badge |
| `/dashboard` | Show full ASCII system map of your Claude Code setup |

## Full system map

The `/dashboard` command renders a complete overview of your setup:

```
┌─ Claude Code System Map ─────────────────────────────┐
│  Dashboard mode: box                                  │
├─ MCP Servers ─────────────────────────────────────────┤
│  ● manager-ai  (npx)                                 │
│  ● granola  (npx)                                    │
├─ Plugins ─────────────────────────────────────────────┤
│  ◆ plugin-dashboard                                   │
├─ Agents ──────────────────────────────────────────────┤
│  ▸ marketing-email                                    │
├─ Active Hook Events ─────────────────────────────────-┤
│  ⚡ SessionStart                                      │
└───────────────────────────────────────────────────────┘
```

## How it works

- A **SessionStart hook** injects tool categorization rules into Claude's system prompt
- Claude renders the visualization at the end of each response (no MCP server needed)
- Display mode is persisted to `.claude/dashboard-mode.local` (git-ignored)
- Tool categories: MCP, File, Agent, Shell, Web, Skill, Todo

## Structure

```
.claude-plugin/plugin.json    # Plugin manifest
hooks/hooks.json              # Hook registration
hooks-handlers/session-start.sh  # Prompt injection logic
commands/dashboard-toggle.md  # Toggle slash command
commands/dashboard.md         # System map slash command
scripts/toggle-mode.sh        # Mode cycling script
scripts/render-dashboard.sh   # ASCII system map renderer
```

## License

MIT
