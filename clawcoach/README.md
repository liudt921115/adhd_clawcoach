# 🧠 ClawCoach

> Energy-aware AI behaviour coaching for ADHD-trait users, built on OpenClaw.

ClawCoach is not a task manager. It's the **regulation layer between intention and action** — a behaviour coaching system that holds your direction steady while continuously adapting *how* you get there based on your current energy and state.

Built as an [OpenClaw](https://openclaw.ai) skill. Runs in Telegram. No app to install.

---

## How decisions happen

Every coaching action originates from a **state transition**, not a periodic ping.

```
User message or cron job fires
  → SKILL.md reads state.json + tasks.json
  → Determines if a state transition occurred
  → Writes new state.json
  → Cancels obsolete cron jobs (cron.remove)
  → Creates new cron jobs (cron.add) with precise timestamps
  → Sends message if transition warrants one
  → Silent otherwise
```

The **heartbeat** (every 5 min) is a bash watchdog only — it checks that the cron jobs that *should* exist actually do. It never initiates coaching. If everything is fine, it returns `HEARTBEAT_OK` which the Gateway silently drops.

---

## Task priority system

Every task has urgency (1–5), importance (1–5), and inferred activation cost (1–5).

```
score = 0.45 × urgency + 0.45 × importance + 0.10 × activation_cost
```

When you add a task, ClawCoach asks two questions (urgency + importance) and places the task in the right position in the queue. At low energy, the ranking shifts to surface easier-to-start tasks first — not because your goals changed, but because you can't start what you can't activate.

---

## Cron job model

All proactive messages come from one-shot cron jobs created at the moment of a state transition. They fire once, deliver to your Telegram DM, and auto-delete.

| Trigger | Jobs created |
|---------|-------------|
| Task started | `focus-check` (+90s) · `hyperfocus-guard` (+30min, recurring) |
| Task switched | Cancel old jobs · Create new jobs for new task |
| Calendar event added | `interrupt-prep` · `interrupt-final` · `resume-reminder` |
| Low energy | `recovery-check` (+60min) |
| Fail-safe entered | All task crons cancelled · `failsafe-check` (+24h) |
| Onboarding complete | `morning-start` · `sleep-guard` · meal reminders (all recurring) |

---

## Repository structure

```
clawcoach/
├── skills/
│   └── clawcoach/
│       └── SKILL.md               # Coaching brain: state machine, task registry,
│                                  # cron scheduling, language rules
├── workspace_template/
│   ├── HEARTBEAT.md               # Watchdog: calls script, dispatches alerts
│   ├── scripts/
│   │   └── heartbeat-check.sh     # Bash: all watchdog logic (no LLM arithmetic)
│   ├── state.json                 # FSM state, active task, cron job list
│   ├── tasks.json                 # Task registry with priority scores
│   ├── memory.md                  # Long-term user context
│   ├── today.md                   # Daily log
│   ├── routine.md                 # Meal, rest, sleep schedule
│   ├── calendar.md                # Events for interrupt detection
│   ├── energy_log.json            # Time-series energy + daily summaries
│   └── RULES.md                   # Hard inviolable rules
├── docs/
│   ├── architecture.md
│   ├── commands.md
│   └── multi-user.md
├── scripts/
│   └── setup.sh
└── README.md
```

---

## Quickstart

### 1. Register the agent

```bash
openclaw agents add clawcoach
# wizard creates ~/.openclaw/workspaces/clawcoach/ and agentDir
```

### 2. Copy ClawCoach files

```bash
git clone https://github.com/your-org/clawcoach.git
cd clawcoach
cp -r workspace_template/* ~/.openclaw/workspaces/clawcoach/
cp -r skills/clawcoach ~/.openclaw/skills/
chmod +x ~/.openclaw/workspaces/clawcoach/scripts/heartbeat-check.sh
```

### 3. Configure openclaw.json

```json
{
  "agents": {
    "list": [
      {
        "id": "clawcoach",
        "workspace": "~/.openclaw/workspaces/clawcoach",
        "heartbeat": {
          "every": "5m",
          "target": "last",
          "model": "anthropic/claude-haiku-4-5-20251001",
          "prompt": "Run heartbeat-check.sh using exec tool. If output is HEARTBEAT_OK reply HEARTBEAT_OK. Otherwise read HEARTBEAT.md for the alert type and execute the action."
        }
      }
    ]
  },
  "bindings": [
    {
      "agentId": "clawcoach",
      "match": { "channel": "telegram", "accountId": "YOUR_BOT_TOKEN_ID" }
    }
  ]
}
```

Note: Heartbeat uses Haiku (cheap, fast) — it's almost always returning HEARTBEAT_OK.
Actual coaching conversations use the default model (Sonnet).

### 4. Start and onboard

```bash
openclaw gateway
# Then message your Telegram bot: /start
```

---

## Talking to ClawCoach

```
/start                     → Onboarding (goals, tasks, routine, style, first task)
/status                    → Current state, active task, top 3 priority queue
"Add: review PR from Sam"  → Triggers urgency/importance questions, adds to queue
"I'm starting [task]"      → RUNNING state, focus-check + hyperfocus-guard scheduled
"I'm stuck"                → Intent Check triggered
"I'm tired"                → Low energy mode, task granularity reduced
"Switch to [task]"         → Old crons cancelled, new task crons created
"I have a meeting at 3pm"  → Interrupt chain scheduled (prep + final + resume)
"I'm done"                 → Closure loop, daily summary, tomorrow's first task
```

---

## Key design decisions

**State machine drives everything.** The LLM executes actions; bash scripts and explicit state transitions make decisions. No ad-hoc coaching.

**Task registry is the source of truth.** `tasks.json` stores every task with its score. Today.md is a display view, not the record. Tasks are never deleted — only status-changed.

**Cron jobs are ephemeral.** One-shot jobs fire once and disappear. The only recurring jobs are routine (morning, sleep, meals) — created once at onboarding.

**Heartbeat is a safety net.** It never initiates a coaching action. It only asks: "do the cron jobs that should exist actually exist?" — useful after a Gateway restart.

**Silence is correct behaviour.** If the user is working and everything is on track, ClawCoach says nothing.

---

## License

MIT
