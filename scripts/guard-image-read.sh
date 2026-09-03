#!/bin/sh
# D4 - screenshot discipline, as a PreToolUse guard on Read.
#
# In the measured corpus one session spent 7.68 MB of tool-result payload on 63
# image reads - 96% of everything it observed - with a single read at 229,852
# characters. Screenshots are worth looking at; they are not worth leaving
# resident in a transcript for the rest of the day.
#
# This blocks the read and hands back the path and size instead. The image is on
# disk and has not moved.
#
# THE ESCAPE HATCH IS DELIBERATE AND MUST STAY EASY: `touch .flow/see` and read
# again. The marker is consumed by the read it permits, so it never silently
# disables the guard. This is a default, not a prohibition - a UI defect you
# cannot see is worse than an expensive transcript.
. "$(dirname "$0")/_common.sh"

slug=$(effort_slug) || exit 0
[ -n "$slug" ] || exit 0

payload=$(cat 2>/dev/null)
path=$(printf '%s' "$payload" | grep -o '"file_path"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*"\([^"]*\)"$/\1/')
[ -n "$path" ] || exit 0

case "$(printf '%s' "$path" | tr 'A-Z' 'a-z')" in
  *.png|*.jpg|*.jpeg|*.webp|*.gif|*.bmp) ;;
  *) exit 0 ;;
esac

# Deliberate read: burn the marker and get out of the way.
if [ -f .flow/see ]; then
  rm -f .flow/see
  exit 0
fi

[ -f "$path" ] || exit 0

bytes=$(wc -c < "$path" 2>/dev/null | tr -d ' ')
case "$bytes" in ''|*[!0-9]*) bytes=0 ;; esac

# Small images cost little and blocking them is pure friction.
[ "$bytes" -lt 40000 ] && exit 0

kb=$(( bytes / 1024 ))
{
  printf 'flow: image read blocked - %s is %s KB and would stay in context all session.\n' "$path" "$kb"
  printf '  The file is on disk and unchanged. Reference it by path in the commit or the handoff.\n'
  printf '  If you actually need to SEE it - a visual check, a UI defect, /flow:eyes - run\n'
  printf '  `touch .flow/see` and read it again. The marker is consumed by that one read.\n'
} >&2
exit 2
