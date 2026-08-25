#!/bin/sh
# D2b - the context backstop. NOT the trigger.
#
# Phase boundaries end sessions (phase-boundary.sh). This catches the case a
# phase boundary structurally cannot: a single runaway task. In the measured
# corpus one loop iteration burned 257 turns and $124 inside one task, and no
# boundary would have interrupted it.
#
# It should almost never fire. A session that trips it is evidence that the
# phase was sized wrong, which is worth saying out loud in the handoff.
. "$(dirname "$0")/_common.sh"

slug=$(effort_slug) || exit 0
[ -n "$slug" ] || exit 0

plan=$(plan_file "$slug")

# Threshold from the plan's Ground rules, else the default. 400K sits above the
# ~250-300K cost knee and above the peak of the cheapest measured session, so a
# correctly sized phase never reaches it.
limit=$(ground_rule "$plan" 'Context backstop')
case "$limit" in
  ''|*[!0-9]*) limit=400000 ;;
esac

# CLAUDE_TRANSCRIPT_PATH is honoured when the harness supplies one; the mtime
# scan in transcript_file is the path that was actually verified.
t=$(transcript_file "$CLAUDE_TRANSCRIPT_PATH") || exit 0
[ -n "$t" ] || exit 0

ctx=$(live_context "$t") || exit 0
[ -n "$ctx" ] || exit 0
[ "$ctx" -lt "$limit" ] && exit 0

printf 'flow: CONTEXT BACKSTOP - this session is at %s, over its %s budget.\n' "$(fmt_k "$ctx")" "$(fmt_k "$limit")"
printf '  A phase boundary should have ended this session before now, so the current\n'
printf '  phase was sized wrong. Finish ONLY the task in hand, then:\n'
printf '    1. Commit it.\n'
printf '    2. Update HANDOFF-%s.md, and note there that this phase overran its budget.\n' "$slug"
printf '    3. Stop the loop and run /flow:loop to continue on fresh context.\n'
exit 0
