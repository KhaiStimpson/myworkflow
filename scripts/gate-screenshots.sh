#!/bin/sh
# H2 - PreToolUse on git commit. Every front-end defect in the mined corpus was
# found by a human looking at the running app AFTER a green test run. This is the
# gate that stops a UI commit landing with nothing to look at.
. "$(dirname "$0")/_common.sh"

payload=$(read_payload)
cmd=$(json_str "$payload" '.tool_input.command')

# Deliberate override, for a CSS change with no visible effect.
case "$cmd" in *"[skip-eyes]"*) exit 0 ;; esac

staged=$(git diff --cached --name-only 2>/dev/null) || exit 0
[ -n "$staged" ] || exit 0

ui=$(printf '%s\n' "$staged" | grep "$UI_PATTERN" 2>/dev/null)
[ -n "$ui" ] || exit 0

branch=$(git branch --show-current 2>/dev/null)
slug=${branch##*/}
[ -n "$slug" ] || slug=$(effort_slug)

shots=""
[ -d "docs/screenshots/$slug" ] && shots=$(ls -A "docs/screenshots/$slug" 2>/dev/null)
[ -n "$shots" ] && exit 0

first=$(printf '%s\n' "$ui" | head -3 | tr '\n' ' ')
deny "This commit stages UI files ($first) and docs/screenshots/$slug/ is empty. Invoke the eyes skill first: capture desktop 1280x800 and mobile 390x844 into docs/screenshots/$slug/ and look at them, then commit again. A green build is not done for anything a person can see. If this change genuinely has no visible effect, add [skip-eyes] to the commit message."
