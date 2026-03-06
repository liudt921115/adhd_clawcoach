# 🧠 ClawCoach

> Energy-aware AI behaviour coaching for ADHD-trait users, built on OpenClaw.

ClawCoach is not a task manager. It's the **regulation layer between intention and action** — a behaviour coaching system that holds your direction steady while continuously adapting *how* you get there based on your current energy and state.

Built as an [OpenClaw](https://openclaw.ai) skill. Runs in Telegram. No app to install.

---

## How it works

ClawCoach lives in your Telegram. It:
- **Adjusts tasks continuously** based on your energy (full task → micro task → just open the file)
- **Checks in proactively** via the Heartbeat loop — but stays silent when you're doing well
- **Detects resistance** and helps you find the real block, not just push harder
- **Resets gracefully** after bad periods — no shame loops, no stats, just 2-minute tasks
- **Remembers you** across sessions, building a picture of what actually works for you

---

## Quickstart

### Prerequisites
- [OpenClaw](https://openclaw.ai) installed and running
- Telegram bot token (from [@BotFather](https://t.me/BotFather))
- Anthropic API key

### 1. Clone this repo

```bash
git clone https://github.com/your-org/clawcoach.git
cd clawcoach
```

### 2. Set up your OpenClaw workspace

```bash
# Copy the workspace template to your OpenClaw workspace directory
cp -r workspace_template/* ~/.openclaw/workspaces/clawcoach/

# Run the setup script to initialise per-user state files
./scripts/setup.sh
```

### 3. Install the skill

```bash
# Copy the skill into OpenClaw's skills directory
cp -r skills/clawcoach ~/.openclaw/skills/
```

### 4. Configure OpenClaw

Add to your `openclaw.json`:

```json
{
  "telegram": {
    "token": "YOUR_TELEGRAM_BOT_TOKEN"
  },
  "models": {
    "primary": {
      "provider": "anthropic",
      "model": "claude-sonnet-4-20250514",
      "api_key": "YOUR_ANTHROPIC_API_KEY"
    }
  },
  "heartbeat": {
    "interval_minutes": 30
  },
  "workspace": "~/.openclaw/workspaces/clawcoach"
}
```

### 5. Start OpenClaw

```bash
openclaw gateway
```

### 6. Message your bot

Find your bot on Telegram and send:
```
/start
```

ClawCoach will begin onboarding. It takes about 5 minutes to set up your goals, routine, and energy baseline.

---

## Repository structure

```
clawcoach/
├── skills/
│   └── clawcoach/
│       └── SKILL.md          # The coaching brain — state machine, all regulation logic
├── workspace_template/
│   ├── HEARTBEAT.md          # Proactive check loop (runs every 30 min)
│   ├── memory.md             # Long-term user context (seeded during onboarding)
│   ├── state.json            # FSM state, energy, active task, granularity
│   ├── today.md              # Daily task list and completion log
│   ├── routine.md            # Meal, rest, sleep schedule
│   ├── calendar.md           # Upcoming events for interrupt detection
│   ├── energy_log.json       # Time-series energy tracking (Evolution Layer)
│   └── RULES.md              # Hard rules the model must always follow
├── docs/
│   ├── architecture.md       # Full system design
│   ├── onboarding.md         # What happens on /start
│   ├── commands.md           # Full command reference
│   └── multi-user.md        # Deploying for multiple users
├── scripts/
│   └── setup.sh             # Workspace initialisation script
└── README.md
```

---

## Talking to ClawCoach

### Starting your day
```
Good morning
→ ClawCoach checks your energy, reviews today's priorities, suggests where to start

/energy high
→ Sets energy to high, unlocks full task granularity

What should I work on?
→ Runs priority engine, returns top task with suggested approach
```

### During work
```
I'm stuck
→ Triggers Intent Check: real want vs. should-do pressure

This task is too big
→ Shrinks task to next granularity level

I need a break
→ Acknowledges, sets return reminder

Let me work on [side project] for a bit
→ Triggers Controlled Drift, sets return time, tracks main track
```

### Energy check-ins
```
/energy low
→ Switches to low-energy mode: micro tasks, reduced expectations, no stats

I'm exhausted today
→ Same as /energy low, interpreted from natural language
```

### End of day
```
I'm done for today
→ Runs Closure Loop: reviews what happened, no judgment, sets tomorrow's first task
```

---

## The files that matter

| File | What it does |
|------|-------------|
| `SKILL.md` | The coaching logic. Edit this to change how ClawCoach behaves. |
| `HEARTBEAT.md` | The proactive loop. Edit check thresholds and actions here. |
| `memory.md` | Your long-term context. ClawCoach writes to this automatically. |
| `state.json` | Current FSM state. You can inspect this to debug behaviour. |
| `routine.md` | Your daily routine. Edit directly or via chat commands. |

---

## Philosophy

ClawCoach is built on one principle: **keep direction, change method**.

- It never changes your goals
- It always changes how you get there based on how you are right now
- It speaks when something changes, and goes quiet when you're okay
- It recognises behaviour, not output
- It never uses the words: efficiency, productivity, discipline, optimize

---

## Contributing

See [docs/architecture.md](docs/architecture.md) for the full system design.

The skill logic lives entirely in `skills/clawcoach/SKILL.md`. This is natural language — no code required to modify coaching behaviour.

---

## License

MIT
