# Architecture

## Layers

```
┌─────────────────────────────────────────────────────┐
│  User (Telegram DM)                                 │
└──────────────────┬──────────────────────────────────┘
                   │ message
┌──────────────────▼──────────────────────────────────┐
│  OpenClaw Gateway                                   │
│  - Telegram adapter                                 │
│  - Session management (per user)                    │
│  - Heartbeat scheduler (every 5min)                 │
│  - Cron scheduler (precise one-shot + recurring)    │
│  - Command queue (serialises per-user)              │
└──────────────────┬──────────────────────────────────┘
                   │ agent turn
┌──────────────────▼──────────────────────────────────┐
│  Agent Loop (Pi framework)                          │
│  Context assembled each turn:                       │
│    RULES.md + SKILL.md + memory.md                  │
│    + state.json + tasks.json + today.md             │
│    + conversation history                           │
│  → Claude API call                                  │
│  → Tool calls: read/write files, cron.add/remove    │
│  → Reply delivered to Telegram                      │
└─────────────────────────────────────────────────────┘
```

## Decision ownership

| Decision | Made by |
|----------|---------|
| State transition occurred? | Claude (SKILL.md) |
| Which cron jobs to create/cancel? | Claude (SKILL.md protocol) |
| Cron job still exists? | bash (heartbeat-check.sh) |
| Timestamp elapsed? | bash (heartbeat-check.sh) |
| Consecutive zero-start days? | bash (heartbeat-check.sh) |
| What to say to the user? | Claude (SKILL.md language rules) |
| Task priority score? | Claude (formula) → stored in tasks.json |
| Energy-adjusted ranking? | Claude (view layer, not stored) |

**Rule:** Any decision that requires reading a number and comparing it to a threshold → bash.
Any decision that requires understanding context, intent, or generating language → Claude.

## State transitions and side effects

Every state transition must:
1. `write_file: state.json` — new FSM state
2. `cron.list` — check what's currently active (avoid duplicates)
3. `cron.remove` for each obsolete job in `state.active_cron_jobs`
4. `cron.add` for each new job needed
5. `write_file: state.json` again — update `active_cron_jobs` list
6. Send message if warranted

Step 2 (cron.list before adding) is important — if the Gateway restarted and
the heartbeat already recreated a missing job, SKILL.md shouldn't create a duplicate.

## Task registry

`tasks.json` is the canonical record of all tasks. It is never overwritten wholesale —
SKILL.md reads it, modifies the relevant task or appends a new one, and writes it back.

`today.md` is a human-readable daily view, not the source of truth.
If today.md and tasks.json conflict, tasks.json wins.

## Cron job naming convention

All ClawCoach cron jobs use the prefix `cc:` for easy scoping:

```
cc:focus-check:<task_id>         one-shot, per task
cc:hyperfocus-guard:<task_id>    one-shot, per task (rescheduled on continuation)
cc:stuck-followup:<task_id>      one-shot, per stuck event
cc:intent-followup:<task_id>     one-shot, per resistance event
cc:recovery-check                one-shot, per low-energy entry
cc:interrupt-prep:<event_id>     one-shot, per calendar event
cc:interrupt-final:<event_id>    one-shot, per calendar event
cc:resume:<event_id>             one-shot, per calendar event
cc:failsafe-check                one-shot, recreated daily while in FAIL_SAFE
morning-start                    recurring, created at onboarding
sleep-guard                      recurring, created at onboarding
meal:lunch                       recurring, created at onboarding
meal:dinner                      recurring, created at onboarding
```

`cron.list` filtered by `cc:` prefix gives a complete picture of active coaching state.

## Multi-user

Each user = one OpenClaw agent with an isolated workspace.
Separate state.json, tasks.json, memory.md, cron jobs, sessions.

For small team MVP (2–5 users):
```bash
openclaw agents add clawcoach-alice
openclaw agents add clawcoach-bob
```

Each agent binds to a different Telegram bot token (one bot per user).
Workspace files are fully isolated — no shared state.

For larger scale: single agent + per-user subdirectories is possible but
requires SKILL.md to route file reads/writes based on sender ID.
Recommended only after validating the single-user model works.

## Cost model

| Component | Model | Frequency | Est. tokens/call |
|-----------|-------|-----------|-----------------|
| User message | Sonnet | On demand | 4k–12k |
| Heartbeat (OK) | Haiku | Every 5min | ~200 |
| Heartbeat (alert) | Haiku | Rare | ~500 |
| Cron job (focus-check) | Haiku | Per task start | ~800 |
| Cron job (morning-start) | Sonnet | Daily | ~3k |
| Cron job (interrupt-prep) | Sonnet | Per event | ~2k |

Haiku for all cron jobs except morning-start and interrupt-prep.
Set `model` field on each cron job payload accordingly.
