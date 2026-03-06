#!/bin/bash
# ClawCoach heartbeat watchdog
# Reads state.json and cron/jobs.json in bash — no LLM for decisions.
# Output: HEARTBEAT_OK or HEARTBEAT_ALERT: <type> <details>
# Called by HEARTBEAT.md on every heartbeat tick (every 5 min).

set -euo pipefail

WORKSPACE="${OPENCLAW_WORKSPACE:-$HOME/.openclaw/workspaces/clawcoach}"
STATE="$WORKSPACE/state.json"
ENERGY_LOG="$WORKSPACE/energy_log.json"
CRON_JOBS="$HOME/.openclaw/cron/jobs.json"
NOW=$(date -u +%s)

# ── Helpers ──────────────────────────────────────────────────────────────────

py() { python3 -c "$1" 2>/dev/null || echo ""; }

read_state() {
  py "import json; d=json.load(open('$STATE')); print(d.get('$1',''))"
}

iso_to_epoch() {
  # Convert ISO 8601 timestamp to unix epoch
  local ts="$1"
  py "import datetime; print(int(datetime.datetime.fromisoformat('${ts}'.replace('Z','+00:00')).timestamp()))" 2>/dev/null || echo 0
}

job_exists() {
  # Check if a cron job with name containing $1 exists and is enabled
  local name_pattern="$1"
  py "
import json, sys
try:
  jobs = json.load(open('$CRON_JOBS')).get('jobs', [])
  found = any('$name_pattern' in j.get('name','') and j.get('enabled', True) for j in jobs)
  print('true' if found else 'false')
except: print('false')
"
}

count_zero_start_days() {
  # Count consecutive days (most recent first) with startup_successes = 0
  py "
import json
try:
  log = json.load(open('$ENERGY_LOG'))
  days = [e for e in log if e.get('type') == 'day_summary']
  days.sort(key=lambda x: x.get('date',''), reverse=True)
  count = 0
  for d in days[:7]:
    if d.get('startup_successes', 0) == 0:
      count += 1
    else:
      break
  print(count)
except: print(0)
"
}

# ── Read current state ────────────────────────────────────────────────────────

FSM=$(read_state "fsm_state")
FSM_SUB=$(read_state "fsm_substate")
FAIL_SAFE=$(read_state "fail_safe_active")
ONBOARDED=$(read_state "onboarding_complete")

# Not onboarded yet — nothing to watch
[ "$ONBOARDED" != "true" ] && echo "HEARTBEAT_OK" && exit 0

# In IDLE — nothing to watch (recurring crons handle routine)
[ "$FSM" = "IDLE" ] && echo "HEARTBEAT_OK" && exit 0

# Already in FAIL_SAFE — failsafe-check cron handles recovery, not us
[ "$FSM_SUB" = "FAIL_SAFE" ] && echo "HEARTBEAT_OK" && exit 0

# ── Check 1: Fail-safe candidate ─────────────────────────────────────────────
# Script makes this determination — no LLM reasoning needed

ZERO_DAYS=$(count_zero_start_days)
if [ "$ZERO_DAYS" -ge 3 ] && [ "$FAIL_SAFE" != "true" ]; then
  echo "HEARTBEAT_ALERT: trigger-failsafe zero_days=${ZERO_DAYS}"
  exit 0
fi

# ── Check 2: Missing focus-check (RUNNING state) ─────────────────────────────

if [ "$FSM" = "RUNNING" ]; then
  TASK_ID=$(py "import json; d=json.load(open('$STATE')); t=d.get('active_task') or {}; print(t.get('id',''))")
  TASK_START_ISO=$(py "import json; d=json.load(open('$STATE')); print(d.get('task_start_time',''))")
  LAST_ACT_ISO=$(py "import json; d=json.load(open('$STATE')); print(d.get('last_activity','') or '')")

  if [ -n "$TASK_ID" ] && [ -n "$TASK_START_ISO" ]; then
    TASK_START=$(iso_to_epoch "$TASK_START_ISO")
    ELAPSED=$(( NOW - TASK_START ))

    # Task started more than 3min ago — focus-check should exist
    if [ "$ELAPSED" -gt 180 ]; then
      FOCUS_EXISTS=$(job_exists "cc:focus-check:${TASK_ID}")

      # focus-check should exist if last_activity is null (user hasn't logged anything)
      if [ "$FOCUS_EXISTS" = "false" ] && [ -z "$LAST_ACT_ISO" ]; then
        echo "HEARTBEAT_ALERT: missing-focus-check ${TASK_ID} elapsed=${ELAPSED}s"
        exit 0
      fi
    fi

    # ── Check 3: Missing hyperfocus-guard ──────────────────────────────────
    # Should exist any time a task has been running >5min
    if [ "$ELAPSED" -gt 300 ]; then
      GUARD_EXISTS=$(job_exists "cc:hyperfocus-guard:${TASK_ID}")
      if [ "$GUARD_EXISTS" = "false" ]; then
        echo "HEARTBEAT_ALERT: missing-hyperfocus-guard ${TASK_ID} elapsed=${ELAPSED}s"
        exit 0
      fi
    fi
  fi
fi

# ── All clear ────────────────────────────────────────────────────────────────

echo "HEARTBEAT_OK"
