#!/bin/sh
# H3 - PreToolUse on push, merge and EF migrations.
#   P3: nothing reaches dev until the whole effort is reviewed.
#   T3: never re-scaffold or squash migrations - the one unrecoverable mistake here.
. "$(dirname "$0")/_common.sh"

payload=$(read_payload)
cmd=$(json_str "$payload" '.tool_input.command')

# --- T3: migrations. Only fires in a repo that actually has them. ---
case "$cmd" in
  *"ef migrations remove"*|*"ef migrations"*"--force"*|*"migrations squash"*)
    if find . -type d -name Migrations -not -path './.git/*' 2>/dev/null | grep -q .; then
      deny "Blocked: never re-scaffold or squash migrations. A migration that has already been applied to a real database cannot be recreated from the model, and the record of what was applied is not recoverable. If this migration was never applied anywhere, say so and do it by hand."
    fi
    ;;
esac

# --- P3: protect the default branch while an effort is in flight. ---
case "$cmd" in
  *"git push"*|*"git merge"*) ;;
  *) exit 0 ;;
esac

case "$cmd" in
  *" dev"*|*"origin dev"*|*"/dev"*|*" main"*|*"origin main"*|*"/main"*) ;;
  *) exit 0 ;;
esac

integration=$(git branch --list 'integration/*' 2>/dev/null | sed 's/^[* ]*//' | head -1)
[ -n "$integration" ] || exit 0

deny "Blocked: an integration branch is live ($integration) and this targets dev or main. Nothing reaches dev until the whole effort is reviewed - ticket branches merge --no-ff into the integration branch, and one PR opens at the end. If the effort is genuinely finished, invoke the wrap skill to open that PR rather than pushing directly."
