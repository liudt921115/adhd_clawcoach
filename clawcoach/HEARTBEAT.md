# ClawCoach — Heartbeat Checklist

<!-- 
  OpenClaw reads this file on every heartbeat tick (default: every 30 minutes).
  The agent works through each check in order and STOPS at the first action needed.
  If no check triggers, respond with exactly: HEARTBEAT_OK
  The Gateway drops HEARTBEAT_OK silently. The user is never disturbed.
  
  This file is the proactive regulation loop. It is what makes ClawCoach feel alive.
-->

---

## Before running checks

Read the following files:
- `state.json` — current FSM state, energy, granularity, active task, drift status
- `today.md` — what has been done, what is active, last activity timestamp
- `routine.md` — scheduled meals, breaks, sleep target
- `calendar.md` — upcoming events
- `energy_log.json` — recent energy entries and startup success counts

---

## Check 1 — Urgent Calendar Interrupt (HIGHEST PRIORITY)

Read `calendar.md`. For each upcoming event:
- Calculate: `prep_time` (from event metadata, default 15 min) + 15 min buffer
- If `current_time >= event_start - prep_time - 15min`:

→ Set `state.json` → `fsm_substate: URGENT_INTERRUPT`
→ Message the user with:
  1. Name of the event and time remaining
  2. 2–3 specific preparation steps relevant to that event type
  3. A clear, calm signal to wrap up current work
→ **STOP. Do not run further checks this tick.**

If no event is imminent: proceed to Check 2.

---

## Check 2 — Critical Task Inactivity

Read `state.json`:
- If `fsm_state = RUNNING`
- AND `active_task.score >= 4.2` (critical task)
- AND `last_activity` is older than 45 minutes
- AND `fsm_substate` is not already STUCK or RESISTANCE

→ Set `state.json` → `fsm_state: ADJUSTING`, `fsm_substate: STUCK`
→ Send one warm, brief check-in. Do not mention the time elapsed. Do not guilt.
  Example: "Hey — how's [task name] going? Need help breaking it down?"
→ **STOP.**

If not triggered: proceed to Check 3.

---

## Check 3 — Routine Guard

Read `routine.md` and current time. Check in this order:

**3a — Sleep Guard:**
If `current_time >= sleep_target - 30min`:
→ Send gentle wind-down message. Acknowledge what was done today (check `today.md`).
  Ask: "Want to do a quick close-out before winding down?"
→ If user responds affirmatively: trigger Closure Loop (see SKILL.md)
→ **STOP.**

**3b — Meal reminder:**
If any meal time is within 15 minutes AND no meal logged in `today.md` for this meal:
→ Send one brief meal reminder. Do not frame as a productivity intervention.
  Example: "It's almost lunch. Take a proper break."
→ Log reminder sent in `today.md`
→ **STOP.**

**3c — Break needed:**
If `last_activity` is not null AND current session duration > 90 minutes continuous:
AND no break logged in `today.md` in the past 90 minutes:
→ Suggest a break appropriate to energy level:
  - Low energy: "You've been at it for a while. A short rest might help more than pushing through."
  - Medium/High: "90 minutes straight — good stretch. 5 minutes away?"
→ **STOP.**

If no routine trigger: proceed to Check 4.

---

## Check 4 — Fail-Safe Detection

Read `energy_log.json`. Count the most recent consecutive days where `day_summary.startup_successes = 0`:

If count >= 3 AND `state.json` → `fail_safe_active` is NOT already true:
→ Set `state.json` → `fsm_state: ADJUSTING`, `fsm_substate: FAIL_SAFE_RESET`, `fail_safe_active: true`
→ Send ONE warm message. Short. No statistics. No mention of the count.
  Do not use: efficiency, productivity, back on track, streak.
  Example tone: "Things have been heavy. Let's just do one small thing today — not to catch up, just to keep the thread."
→ **STOP.**

If already in FAIL_SAFE_RESET: skip this check, proceed to Check 5.
If count < 3: proceed to Check 5.

---

## Check 5 — Energy Recovery Detection

Read `energy_log.json`. Check the last 2 daily entries:

If BOTH of the following are true:
- `day_summary.startup_successes >= 1` for each of the last 2 days
- `day_summary.dominant_energy` is "medium" or "high" for each

AND current `state.json` shows reduced granularity (level < 3) OR `fail_safe_active: true`:

→ If in FAIL_SAFE_RESET:
  - Exit reset: set `fail_safe_active: false`
  - Transition FSM to RUNNING
  - Restore granularity to level 1 (not full — stay gentle)
  - Send brief acknowledgement of the turnaround. Specific, not evaluative.

→ If granularity is reduced but not in reset:
  - Restore granularity one level (e.g., 1 → 2)
  - Update `state.json`
  - Send brief message noting the adjustment

→ **STOP.**

If no recovery detected: proceed to Check 6.

---

## Check 6 — General Inactivity (Lowest Priority)

Read `state.json`:
- If `fsm_state = RUNNING`
- AND `last_activity` is older than 90 minutes
- AND no other check triggered this tick
- AND `fsm_substate` is null (not already in an adjusting state)

→ Send ONE gentle, low-pressure nudge. Offer to shrink the task.
  Example: "Still with [task]? Happy to make it smaller if you need."
→ Set `state.json` → `fsm_substate: STUCK`
→ **STOP.**

---

## Default — No checks triggered

If none of the above checks triggered:
→ Respond with exactly: `HEARTBEAT_OK`
→ Do not send any message to the user.
→ The Gateway drops this response silently.

The user is doing fine. The system is invisible. This is correct behaviour.
