#!/usr/bin/env bash
# Pixel Dweller autonomous dev loop.
# task -> branch -> worker codegen -> local tests -> PR -> CI -> Claude review
# -> auto-merge -> deploy. State lives in TRACKER.md + tasks/*.md.
#
# Usage:
#   scripts/dev-loop.sh once     # do ONE ready task, then exit (cron uses this)
#   scripts/dev-loop.sh watch    # loop until no ready tasks / paused / cap hit
#
# Budget guardrails: cron tick is this shell script (free). Claude is invoked
# ONLY to review a green PR. Retry cap then model escalation then 'blocked'.

set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
GODOT="${GODOT:-$HOME/.local/bin/godot}"
TRACKER="$ROOT/TRACKER.md"
LOG() { echo "[$(date '+%F %T')] $*"; }
ctl() { grep -E "^$1:" "$TRACKER" | head -1 | sed -E "s/^$1:[[:space:]]*//; s/[[:space:]]*#.*//"; }

PAUSED="$(ctl paused)"
[ "$PAUSED" = "true" ] && { LOG "Loop PAUSED in TRACKER.md. Exiting."; exit 0; }

CAP="$(ctl max_tasks_per_day)";        CAP="${CAP:-8}"
DONE_TODAY="$(ctl tasks_merged_today)"; DONE_TODAY="${DONE_TODAY:-0}"
DEF_WORKER="$(ctl default_worker)";    DEF_WORKER="${DEF_WORKER:-opencode/big-pickle}"
ESC_WORKER="$(ctl escalation_worker)"; ESC_WORKER="${ESC_WORKER:-hermes/grok}"
RETRY_CAP="$(ctl retry_cap)";          RETRY_CAP="${RETRY_CAP:-2}"

if [ "$DONE_TODAY" -ge "$CAP" ]; then LOG "Daily cap ($CAP) reached. Exiting."; exit 0; fi

# --- pick next ready task: first 'todo' whose depends_on are all 'done' ---
next_task() {
  for f in $(ls tasks/*.md 2>/dev/null | sort); do
    st=$(grep -E '^status:' "$f" | sed -E 's/status:[[:space:]]*//')
    [ "$st" = "todo" ] || [ "$st" = "failed" ] || continue
    deps=$(grep -E '^depends_on:' "$f" | sed -E 's/depends_on:[[:space:]]*//; s/,/ /g')
    ok=1
    for d in $deps; do
      [ "$d" = "none" ] && continue
      dst=$(grep -E '^status:' "tasks/$d.md" 2>/dev/null | sed -E 's/status:[[:space:]]*//')
      [ "$dst" = "done" ] || ok=0
    done
    [ "$ok" = "1" ] && { echo "$f"; return 0; }
  done
  return 1
}

run_one() {
  local tf id title attempts worker branch
  tf="$(next_task)" || { LOG "No ready tasks."; return 9; }
  id=$(grep -E '^id:' "$tf" | sed -E 's/id:[[:space:]]*//')
  title=$(grep -E '^title:' "$tf" | sed -E 's/title:[[:space:]]*//')
  attempts=$(grep -E '^attempts:' "$tf" | sed -E 's/attempts:[[:space:]]*//'); attempts=${attempts:-0}
  worker="$DEF_WORKER"; [ "$attempts" -ge "$RETRY_CAP" ] && worker="$ESC_WORKER"
  branch="feat/$id"
  LOG "TASK $id ($title) attempt $((attempts+1)) worker=$worker"

  git fetch -q origin main 2>/dev/null || true
  git switch -C "$branch" main 2>/dev/null || git switch -C "$branch"

  # --- dispatch codegen to worker (their tokens, not Claude's) ---
  local prompt; prompt="$(cat "$tf")"
  prompt="You are implementing ONE task in a Godot 4.3 project for a web game.
Follow the acceptance criteria EXACTLY. Write GDScript + scenes + GUT tests.
Do not touch unrelated files. Keep files under 500 lines. TASK:
$prompt"
  case "$worker" in
    opencode/*) echo "$prompt" | opencode run -m "$worker" 2>&1 | tail -5 ;;
    hermes/*)   hermes -z "$prompt" --yolo 2>&1 | tail -5 ;;
    *)          echo "$prompt" | opencode run 2>&1 | tail -5 ;;
  esac

  # --- local self-check (free, avoids paid CI retries) ---
  local testfail=0
  if [ -d addons/gut ]; then
    "$GODOT" --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit || testfail=1
  fi

  if [ "$testfail" = "1" ]; then
    LOG "Local tests failed for $id."
    set_field "$tf" attempts "$((attempts+1))"
    if [ "$((attempts+1))" -gt "$RETRY_CAP" ]; then
      set_field "$tf" status blocked
      track "$id" blocked "" "$((attempts+1))" "local tests failing after escalation — needs human"
      return 1
    fi
    set_field "$tf" status failed
    track "$id" failed "" "$((attempts+1))" "local tests failed; will retry"
    return 1
  fi

  # --- commit, push, open PR ---
  git add -A
  git -c user.name='pixel-bot' -c user.email='pratyush.upadhyay2013@gmail.com' \
    commit -q -m "$id: $title" || { LOG "nothing to commit"; return 1; }
  git push -q -u origin "$branch" --force-with-lease
  local pr; pr=$(gh pr create --base main --head "$branch" --title "$id: $title" \
      --body "Automated by dev-loop. Task: $id. Worker: $worker." 2>/dev/null \
      || gh pr view "$branch" --json url -q .url)
  LOG "PR: $pr"
  set_field "$tf" status in_review
  track "$id" in_review "$pr" "$((attempts))" "PR opened; waiting for CI"

  # --- wait for CI ---
  LOG "waiting for CI..."
  if ! gh pr checks "$branch" --watch --interval 20 2>/dev/null; then
    LOG "CI failed for $id."
    set_field "$tf" attempts "$((attempts+1))"
    set_field "$tf" status failed
    track "$id" failed "$pr" "$((attempts+1))" "CI red"
    return 1
  fi

  # --- Claude review (ONLY here; small diff = cheap) ---
  local diff verdict
  diff="$(git diff main...$branch)"
  verdict="$(claude -p "You are the senior reviewer. Review this diff against the task spec.
Reply with exactly APPROVE or REJECT on the first line, then a one-line reason.
TASK SPEC:
$(cat "$tf")
DIFF:
$diff" 2>/dev/null | head -3)"
  LOG "Review: $verdict"

  if echo "$verdict" | head -1 | grep -qi '^APPROVE'; then
    gh pr merge "$branch" --squash --delete-branch 2>/dev/null
    set_field "$tf" status done
    set_field "$TRACKER_DUMMY" _ _ 2>/dev/null
    bump_daily
    track "$id" done "$pr" "$attempts" "approved + merged + shipping via deploy.yml"
    LOG "MERGED $id -> deploying."
    return 0
  else
    set_field "$tf" attempts "$((attempts+1))"
    set_field "$tf" status failed
    track "$id" failed "$pr" "$((attempts+1))" "Claude REJECT: $(echo "$verdict" | tail -1)"
    return 1
  fi
}

set_field() { # set_field <file> <key> <value>
  local f="$1" k="$2" v="$3"; [ -f "$f" ] || return 0
  if grep -qE "^$k:" "$f"; then
    sed -i -E "s|^$k:.*|$k: $v|" "$f"
  fi
}
bump_daily() {
  local n; n="$(ctl tasks_merged_today)"; n="${n:-0}"
  sed -i -E "s|^tasks_merged_today:.*|tasks_merged_today: $((n+1))|" "$TRACKER"
}
track() { # append activity log line
  local id="$1" st="$2" pr="$3" att="$4" note="$5"
  sed -i "/^## Activity log/a - $(date '+%F %T') — $id → $st (att $att) ${pr:+$pr} — $note" "$TRACKER"
}

case "${1:-once}" in
  once)  run_one ;;
  watch) while run_one; do sleep 5; done ;;
  *)     echo "usage: $0 once|watch"; exit 2 ;;
esac
