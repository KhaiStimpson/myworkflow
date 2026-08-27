#!/bin/sh
# H4 - SessionEnd and PreCompact. Writes only the mechanical spine of the handoff.
#
# A shell hook cannot author a handoff. Branch, SHA, phase and dirty files it can
# record; "do not re-litigate" and "landmines" are judgements only the session that
# lived through them can write. So this writes between markers and never touches
# the prose sections - the wrap skill owns those.
. "$(dirname "$0")/_common.sh"

slug=$(effort_slug) || exit 0
[ -n "$slug" ] || exit 0

file="HANDOFF-$slug.md"
plan=$(plan_file "$slug")
branch=$(git branch --show-current 2>/dev/null || echo unknown)
sha=$(git rev-parse --short HEAD 2>/dev/null || echo unknown)
phase=$(current_phase "$plan" 2>/dev/null)
[ -n "$phase" ] || phase="all phases complete"
next=$(grep -m1 -- '- \[ \]' "$plan" 2>/dev/null || echo "none - all tasks checked")
dirty=$(git status --porcelain 2>/dev/null | head -20)
[ -n "$dirty" ] || dirty="(clean)"

# D2 - which phase this session owned, and where it sits in the chain. Under
# "one phase, one session" an effort is a sequence of sessions, and a handoff
# that does not say which link it is leaves the next one guessing.
owned=$(session_phase 2>/dev/null)
count=$(cat .flow/session-count 2>/dev/null | tr -d ' \t\r\n')
case "$count" in ''|*[!0-9]*) count=1 ;; esac

spine=$(
  # Every line goes through '%s\n'. A format string starting with "-" is read as
  # an option by dash, which is what /bin/sh is on most Linux boxes.
  printf '%s\n' '<!-- flow:spine:start - written by a hook, edited by no one -->'
  printf 'Updated: %s · Branch: `%s` · Last commit: `%s`\n\n' "$(date -u '+%Y-%m-%d %H:%M UTC')" "$branch" "$sha"
  printf '%s\n' "- **Plan:** ${plan:-none}"
  printf '%s\n' "- **Phase:** $phase"
  printf '%s\n' "- **This session owned:** ${owned:-not recorded}"
  printf '%s\n' "- **Session in chain:** $count"
  printf '%s\n' "- **Next task:** $next"
  printf '%s\n\n' "- **Uncommitted:**"
  printf '%s\n%s\n%s\n' '```' "$dirty" '```'
  printf '%s\n' '<!-- flow:spine:end -->'
)

if [ -f "$file" ] && grep -q 'flow:spine:start' "$file"; then
  awk -v spine="$spine" '
    /flow:spine:start/ { print spine; skip=1; next }
    /flow:spine:end/   { skip=0; next }
    !skip              { print }
  ' "$file" > "$file.tmp" && mv "$file.tmp" "$file"
else
  {
    printf '# HANDOFF — %s\n\n' "$slug"
    printf '%s\n\n' 'Untracked. Working state lives here; decisions live in the plan and the design record.'
    printf '%s\n\n' "$spine"
    printf '%s\n\n%s\n\n' '## Do not re-litigate' '_Not yet written — the wrap skill fills this in._'
    printf '%s\n\n%s\n\n' '## Landmines' '_Not yet written._'
    printf '%s\n\n%s\n' '## Open questions' '_Not yet written._'
  } > "$file"
fi
exit 0
