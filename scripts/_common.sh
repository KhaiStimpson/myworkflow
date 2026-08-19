#!/bin/sh
# Shared helpers for flow hooks. POSIX sh only - these run under Git Bash on Windows.

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
