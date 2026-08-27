#!/bin/sh
# H1 - SessionStart. Injects where the live effort stands, so resuming costs no
# keystrokes. Exits silently when no effort is live: plain stdout becomes context,
# so printing nothing is the difference between free and a tax on every session.
. "$(dirname "$0")/_common.sh"

slug=$(effort_slug) || exit 0
[ -n "$slug" ] || exit 0

plan=$(plan_file "$slug")
[ -n "$plan" ] || exit 0

branch=$(git branch --show-current 2>/dev/null || echo "unknown")
next=$(grep -m1 -- '- \[ \]' "$plan" 2>/dev/null || echo "none - all tasks checked")
# The phase the NEXT task sits under - not grep -m1, which always returns
# Phase 1 no matter how far the effort has got.
phase=$(current_phase "$plan" 2>/dev/null)
[ -n "$phase" ] || phase="all phases complete"
# grep -c PRINTS 0 and EXITS 1 when it matches nothing, so `|| echo 0` appends a
# second zero and the count renders as "0\n0". Take the output, then default it.
done_n=$(grep -c -- '- \[x\]' "$plan" 2>/dev/null)
todo_n=$(grep -c -- '- \[ \]' "$plan" 2>/dev/null)
case "$done_n" in ''|*[!0-9]*) done_n=0 ;; esac
case "$todo_n" in ''|*[!0-9]*) todo_n=0 ;; esac

printf 'flow: effort "%s" is live.\n' "$slug"
printf '  plan:     %s (%s done, %s remaining)\n' "$plan" "$done_n" "$todo_n"
printf '  branch:   %s\n' "$branch"
printf '  phase:    %s\n' "$phase"
printf '  next:     %s\n' "$next"

# D2 - a session owns one phase. Claim it now, so phase-boundary.sh has something
# to compare against from the first turn rather than adopting one mid-loop.
#
# This is also where a handed-off phase gets picked up: the predecessor left the
# pending marker deliberately un-cleared so its own handoff could name the phase
# it finished. Claiming here is what advances the chain.
# The one-shot markers the Stop hooks use to avoid blocking a session forever are
# per-session state. A fresh session gets a fresh chance to be told.
rm -f .flow/over-budget .flow/wrap-pending

cur=$(current_phase "$plan" 2>/dev/null)
if [ -n "$cur" ]; then
  set_session_phase "$cur"
  rm -f .flow/handoff-pending
  n=$(cat .flow/session-count 2>/dev/null | tr -d ' \t\r\n')
  case "$n" in ''|*[!0-9]*) n=0 ;; esac
  echo $((n + 1)) > .flow/session-count
  [ "$n" -gt 0 ] && printf '  chain:    session %s of this effort\n' "$((n + 1))"
fi

# D2b - the budget, in front of you while the work happens instead of on a bill
# afterwards. Silent when the transcript cannot be read; this is information,
# never an obstacle.
limit=$(context_limit "$plan")
t=$(transcript_file "$CLAUDE_TRANSCRIPT_PATH" 2>/dev/null)
if [ -n "$t" ]; then
  ctx=$(live_context "$t" 2>/dev/null)
  case "$ctx" in
    ''|*[!0-9]*) ;;
    *) printf '  context:  %s of %s budget\n' "$(fmt_k "$ctx")" "$(fmt_k "$limit")" ;;
  esac
fi
[ -f "HANDOFF-$slug.md" ] && printf '  handoff:  HANDOFF-%s.md - read it before deciding anything\n' "$slug"
[ -f .flow/fog ] && printf '  fog:      %s - a fog session preceded this plan\n' "$(tr -d '\r\n' < .flow/fog)"
printf 'Run /flow:loop to execute the plan. Do not start a second effort alongside this one.\n'
exit 0
