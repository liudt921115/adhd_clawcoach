# Architecture

ClawCoach is built as an OpenClaw skill. It does not run its own servers.

## What OpenClaw provides

| Component | What it does |
|-----------|-------------|
| Gateway process | Receives Telegram messages, manages sessions, serialises per-user queues |
| Heartbeat scheduler | Fires every 30 min, reads HEARTBEAT.md, triggers agent loop |
| Agent loop | Assembles context → calls Claude API → executes tool calls → streams reply |
| Memory system | Injects workspace files (memory.md, state.json, etc.) into every context |
| Telegram adapter | grammY-based connector, handles webhooks and bot API delivery |
| File tools | Read/write Markdown and JSON files in the workspace directory |

## What ClawCoach provides

| File | Role |
|------|------|
| `skills/clawcoach/SKILL.md` | Coaching logic: state machine, all regulation rules, language rules |
| `workspace_template/HEARTBEAT.md` | Proactive loop: 6 ordered checks, Silence Principle implementation |
| `workspace_template/memory.md` | Long-term user context schema and update rules |
| `workspace_template/state.json` | Per-user FSM state schema |
| `workspace_template/today.md` | Daily log structure |
| `workspace_template/routine.md` | Routine configuration |
| `workspace_template/calendar.md` | Calendar event schema for interrupt detection |
| `workspace_template/energy_log.json` | Time-series energy data for Evolution Layer |
| `workspace_template/RULES.md` | Hard inviolable rules injected at all times |

## Data flow

```
User (Telegram)
  ↓ message
OpenClaw Gateway
  ↓ normalise + session lookup
Agent Loop
  ↓ assemble context:
    RULES.md + SKILL.md + memory.md + state.json + today.md + conversation history
  ↓ Claude API call
  ↓ tool calls: read/write workspace files
  ↓ reply
OpenClaw Gateway → Telegram → User

[Parallel: Heartbeat every 30 min]
OpenClaw Scheduler
  ↓ trigger agent loop with HEARTBEAT.md as primary instruction
  ↓ Claude reads checklist, runs checks, either:
     → sends proactive message via Gateway → Telegram → User
     → returns HEARTBEAT_OK (Gateway drops silently)
```

## Per-user workspace structure

```
~/.openclaw/workspaces/clawcoach/
├── HEARTBEAT.md        # Proactive loop (shared template, same for all users)
├── RULES.md            # Hard rules (shared template)
├── memory.md           # Long-term context (unique per user, grows over time)
├── state.json          # Current FSM state (unique per user, updated frequently)
├── today.md            # Daily log (reset each morning, archived to YYYY-MM-DD.md)
├── routine.md          # Routine config (unique per user, set during onboarding)
├── calendar.md         # Upcoming events (unique per user)
├── energy_log.json     # Time-series energy (unique per user, append-only)
└── archive/
    ├── 2026-03-01.md   # Previous today.md files
    └── ...
```

## Multi-user deployment

For multiple users, each user gets their own workspace directory. The OpenClaw Gateway routes messages to the correct workspace based on Telegram user ID.

See `docs/multi-user.md` for deployment details.

## Model recommendation

Primary: `claude-sonnet-4-20250514`
- Strong at following structured instructions (SKILL.md)
- Empathetic tone by default
- Good context window for memory + history + skill

Heartbeat: Consider `claude-haiku-4-5-20251001` for cost efficiency on silent ticks.
