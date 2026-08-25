#!/bin/sh
# D2 - the phase boundary ends the session.
#
# A session owns one phase. When the first unchecked task in the plan moves into
# a LATER phase than the one this session started on, that phase is done and the
# session's useful life is over: everything it learned that matters is already in
# the plan and the handoff, and everything else is transcript nobody should pay
# to re-read.
#
# This prints a directive and exits 0. It never edits the plan and never stops
# anything itself - the loop prompt reads the directive and acts on it, which is
# the load-bearing path. Wiring it to a Stop hook as well is belt and braces.
. "$(dirname "$0")/_common.sh"

slug=$(effort_slug) || exit 0
[ -n "$slug" ] || exit 0

plan=$(plan_file "$slug")
[ -n "$plan" ] && [ -f "$plan" ] || exit 0

# Every box ticked: the effort is over, not the phase. Different ending, and it
# must not spawn a successor that would have nothing to do.
if plan_complete "$plan"; then
  printf 'flow: every task in %s is ticked. The effort is done.\n' "$plan"
  printf '  Do NOT spawn a successor. Stop the loop and run /flow:wrap.\n'
  exit 0
fi

cur=$(current_phase "$plan")
[ -n "$cur" ] || exit 0

# First check of a new session: adopt the phase we found and say nothing. This is
# also the repair path if .flow/phase is lost - a session with no recorded phase
# claims the one it is standing in rather than declaring a false boundary.
started=$(session_phase) || {
  set_session_phase "$cur"
  exit 0
}

[ "$cur" = "$started" ] && exit 0

# The boundary. Leave .flow/phase alone: this session still OWNS the phase it
# finished, and the handoff has to be able to say which one that was. The
# successor claims the next phase at its own session start.
#
# The pending marker is what makes a re-run idempotent, and it is also the signal
# /flow:loop reads to know it must spawn rather than loop here.
[ -f .flow/handoff-pending ] && exit 0
printf '%s' "$started" > .flow/handoff-pending

printf 'flow: PHASE BOUNDARY - "%s" is complete.\n' "$started"
printf '  This session has finished its phase. Before doing anything else:\n'
printf '    1. Commit any uncommitted work from that phase.\n'
printf '    2. Update HANDOFF-%s.md - it is the only thing that crosses the boundary.\n' "$slug"
printf '    3. Stop the loop here. Do NOT start "%s" in this session.\n' "$cur"
printf '  Then run /flow:loop, which spawns a fresh agent on clean context for the next phase.\n'
printf '  The user can override this with one word if the remaining work is small.\n'
exit 0
