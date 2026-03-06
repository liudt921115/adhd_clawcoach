# ClawCoach Heartbeat — Watchdog Only

<!--
  Fires every 5 minutes. This is a safety net, not a coaching mechanism.
  All coaching happens via cron jobs created by SKILL.md on state transitions.
  
  CONTRACT: If the script outputs HEARTBEAT_OK → reply HEARTBEAT_OK, stop.
  Do not send any message to the user.
-->

## Instructions

Run `heartbeat-check.sh` using the exec tool.

Act on output:

| Output | Action |
|--------|--------|
| `HEARTBEAT_OK` | Reply `HEARTBEAT_OK`. Stop. |
| `HEARTBEAT_ALERT: missing-focus-check <task_id>` | Call `cron.add` to recreate `cc:focus-check:<task_id>` (fires in 90s). Send: "Hey — have you got started on [task]? Need help?" |
| `HEARTBEAT_ALERT: missing-hyperfocus-guard <task_id>` | Call `cron.add` to recreate `cc:hyperfocus-guard:<task_id>` (fires in 30min). No message to user. |
| `HEARTBEAT_ALERT: trigger-failsafe` | Write `state.json` → `fsm_substate: FAIL_SAFE`. Call `cron.remove` for all `cc:focus*`, `cc:hyperfocus*`, `cc:stuck*`, `cc:recovery*` jobs. Call `cron.add` for `cc:failsafe-check` (+24h). Send one warm message (see SKILL.md Fail-Safe section). |

The script has already read the files and made the decision.
Claude's only job here is to execute the pre-decided action.
