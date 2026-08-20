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
phase=$(grep -m1 '^## Phase' "$plan" 2>/dev/null || echo "unknown")
done_n=$(grep -c -- '- \[x\]' "$plan" 2>/dev/null || echo 0)
todo_n=$(grep -c -- '- \[ \]' "$plan" 2>/dev/null || echo 0)

printf 'flow: effort "%s" is live.\n' "$slug"
printf '  plan:     %s (%s done, %s remaining)\n' "$plan" "$done_n" "$todo_n"
printf '  branch:   %s\n' "$branch"
printf '  next:     %s\n' "$next"
[ -f "HANDOFF-$slug.md" ] && printf '  handoff:  HANDOFF-%s.md - read it before deciding anything\n' "$slug"
[ -f .flow/fog ] && printf '  fog:      %s - a fog session preceded this plan\n' "$(tr -d '\r\n' < .flow/fog)"
printf 'Run /flow:loop to execute the plan. Do not start a second effort alongside this one.\n'
exit 0
