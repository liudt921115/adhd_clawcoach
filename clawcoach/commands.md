# Commands & Conversations

ClawCoach understands natural language — you don't need to use commands. But these are reliable shortcuts.

---

## Getting started

| Input | What happens |
|-------|-------------|
| `/start` | Begins onboarding. Sets up goals, routine, energy baseline. |
| `/status` | Shows current FSM state, active task, energy level, today's progress. |

---

## Energy

| Input | What happens |
|-------|-------------|
| `/energy high` | Sets energy to high. Full granularity unlocked. |
| `/energy medium` | Sets energy to medium. Standard mode. |
| `/energy low` | Sets energy to low. Switches to micro-task mode. |
| `"I'm exhausted"` | Detected as low energy automatically. |
| `"Feeling good today"` | Detected as medium/high automatically. |

---

## Tasks

| Input | What happens |
|-------|-------------|
| `"What should I work on?"` | Runs priority engine, suggests top task. |
| `"I'm starting [task]"` | Logs startup success, sets active task, sets FSM → RUNNING. |
| `"Done"` / `"Finished"` | Marks active task complete, logs success. |
| `"This is too big"` | Drops granularity one level, reframes task. |
| `"I can't get started"` | Triggers Intent Check. |
| `"I'm stuck"` | Same as above. |
| `/task add [description]` | Adds a task to today.md on the appropriate track. |

---

## Drift & Side track

| Input | What happens |
|-------|-------------|
| `"I need to work on [X] for a bit"` | Triggers Controlled Drift. Sets return time. |
| `"Let me do [X] instead"` | Same as above. |
| `"I'm back"` | Ends drift, returns to main track. |
| `/drift [minutes]` | Explicit drift with specified duration. |

---

## Routine

| Input | What happens |
|-------|-------------|
| `"Move lunch to 2pm"` | Updates today's lunch reminder time. |
| `"Skip dinner reminder today"` | Suppresses that reminder for today. |
| `"No sleep reminder tonight"` | Suppresses Sleep Guard for tonight. |
| `"Update my routine"` | ClawCoach asks what to change and updates routine.md. |

---

## Calendar

| Input | What happens |
|-------|-------------|
| `"I have a meeting tomorrow at 3pm"` | Adds to calendar.md, asks about prep time. |
| `"What's on my calendar this week?"` | Reads calendar.md and summarises. |
| `"Add [event] on [date/time]"` | Adds event with default prep time for event type. |

---

## End of day

| Input | What happens |
|-------|-------------|
| `"I'm done for today"` | Triggers Closure Loop. Review, reflection, tomorrow's first task. |
| `"Wrapping up"` | Same as above. |
| `/done` | Same as above. |

---

## Memory & settings

| Input | What happens |
|-------|-------------|
| `"Remember that [X] works well for me"` | Appends to memory.md patterns. |
| `"What do you know about me?"` | Summarises memory.md in conversational form. |
| `"What's my main goal?"` | Reads and states the main track goal from memory.md. |
| `/memory` | Shows current memory.md content. |

---

## Useful anytime

| Input | What happens |
|-------|-------------|
| `"How am I doing?"` | Reads state.json and today.md, gives honest summary. No spin. |
| `"I need a break"` | Acknowledges, suggests break type based on energy, sets return reminder. |
| `"I'm overwhelmed"` | Detects as resistance. Triggers Intent Check and granularity drop. |
| `"Help"` | Gives a brief reminder of what ClawCoach can do. |

---

## Notes on natural language

ClawCoach understands context. You don't need exact phrases.

- Writing in Chinese? ClawCoach replies in Chinese.
- Expressing frustration? It won't push back or optimise you.
- Saying nothing for hours? The heartbeat will check in if something is active.
- Doing well and not messaging? The heartbeat stays quiet.
