#!/bin/sh
# Shared helpers for flow hooks. POSIX sh only - these run under Git Bash on Windows.

# Read the whole hook payload from stdin once.
read_payload() { cat; }

# Extract a JSON string field without requiring jq. Falls back to sed when jq
# is absent, which is the common case on a fresh Windows checkout.
json_str() {
  _payload="$1"; _path="$2"; _key="${2##*.}"
  if command -v jq >/dev/null 2>&1; then
    printf '%s' "$_payload" | jq -r "$_path // empty" 2>/dev/null && return 0
  fi
  printf '%s' "$_payload" \
    | tr -d '\n' \
    | sed -n "s/.*\"$_key\"[[:space:]]*:[[:space:]]*\"\\(\\([^\"\\\\]\\|\\\\.\\)*\\)\".*/\\1/p" \
    | sed 's/\\"/"/g; s/\\\\/\\/g'
}

# Emit a PreToolUse denial. The reason is shown to Claude, so it says what to do.
deny() {
  printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"%s"}}\n' "$1"
  exit 0
}

# The live effort slug, or empty. Every hook exits silently when this is empty,
# so a repo with no flow effort pays nothing for having the plugin installed.
effort_slug() {
  [ -f .flow/current ] || return 1
  tr -d ' \t\r\n' < .flow/current
}

plan_file() {
  _slug="$1"
  [ -n "$_slug" ] && [ -f "docs/$_slug-plan.md" ] && { printf 'docs/%s-plan.md' "$_slug"; return 0; }
  ls docs/*-plan.md 2>/dev/null | head -1
}

UI_PATTERN='\.\(tsx\|jsx\|vue\|svelte\|razor\|cshtml\|xaml\|css\|scss\|sass\|less\|html\)$'
