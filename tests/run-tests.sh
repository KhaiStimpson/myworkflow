#!/bin/sh
# Seam 1 - the scripts, invoked as processes against a throwaway fixture.
#
# These assert the external contract only: stdout, exit code, and what changed on
# disk. Nothing here reaches inside a script to test a shell function, and nothing
# asserts on exact wording - a test that breaks when a message is reworded is
# testing the wrong thing.
#
# Seam 2 - the skill and template prose - is not testable here and is verified by
# a behavioural run. See docs/spec-session-economics.md, "Testing Decisions".
#
#   sh tests/run-tests.sh

ROOT=$(cd "$(dirname "$0")/.." && pwd)
PASS=0
FAIL=0

fixture() {
  WORK=$(mktemp -d 2>/dev/null || mktemp -d -t flowtest)
  cd "$WORK" || exit 1
  git init -q . 2>/dev/null
  git config user.email t@t.t 2>/dev/null
  git config user.name t 2>/dev/null
  mkdir -p .flow docs
  printf 'demo' > .flow/current
}

teardown() {
  cd "$ROOT" || exit 1
  [ -n "$WORK" ] && rm -rf "$WORK"
  WORK=
}

plan_with() {
  # $1 = which task numbers are ticked, as a space-separated list
  {
    printf '# Demo — plan\n\n## Ground rules\n\n'
    printf -- '- **Build:** `true`\n- **Context backstop:** 120000\n\n'
    printf '## Phase 1 — first\n\n'
    for n in 1 2; do
      case " $1 " in *" p1t$n "*) printf -- '- [x] task %s\n' "$n" ;; *) printf -- '- [ ] task %s\n' "$n" ;; esac
    done
    printf '\n## Phase 2 — second\n\n'
    for n in 1 2; do
      case " $1 " in *" p2t$n "*) printf -- '- [x] task %s\n' "$n" ;; *) printf -- '- [ ] task %s\n' "$n" ;; esac
    done
  } > docs/demo-plan.md
}

transcript_with() {
  # $1 = cache_read tokens. Builds a synthetic transcript in the project dir
  # Claude Code would derive from this cwd, which is the path the scripts scan.
  enc=$(pwd -W 2>/dev/null || pwd)
  enc=$(printf '%s' "$enc" | sed 's#[:/\\]#-#g')
  TDIR="$HOME/.claude/projects/$enc"
  mkdir -p "$TDIR"
  printf '{"type":"assistant","message":{"model":"claude-sonnet-5","usage":{"input_tokens":10,"cache_read_input_tokens":%s,"cache_creation_input_tokens":0,"output_tokens":5}}}\n' "$1" > "$TDIR/synthetic.jsonl"
}

ok() {
  if [ "$1" = "yes" ]; then
    PASS=$((PASS + 1)); printf '  ok   %s\n' "$2"
  else
    FAIL=$((FAIL + 1)); printf '  FAIL %s\n' "$2"
    [ -n "$3" ] && printf '       got: %s\n' "$3"
  fi
}

says() { case "$1" in *"$2"*) echo yes ;; *) echo no ;; esac; }
empty() { [ -z "$1" ] && echo yes || echo no; }
session_phase_of() { cat .flow/phase 2>/dev/null; }

# ---------------------------------------------------------------------------
echo "phase-boundary.sh"
# ---------------------------------------------------------------------------

fixture; plan_with ""
out=$(sh "$ROOT/scripts/phase-boundary.sh" 2>&1)
ok "$(empty "$out")" "silent on first run, and adopts the current phase"
ok "$([ -f .flow/phase ] && echo yes || echo no)" "records the phase it adopted"
teardown

fixture; plan_with ""
sh "$ROOT/scripts/phase-boundary.sh" >/dev/null 2>&1
plan_with "p1t1"
out=$(sh "$ROOT/scripts/phase-boundary.sh" 2>&1)
ok "$(empty "$out")" "silent mid-phase"
teardown

fixture; plan_with ""
sh "$ROOT/scripts/phase-boundary.sh" >/dev/null 2>&1
plan_with "p1t1 p1t2"
out=$(sh "$ROOT/scripts/phase-boundary.sh" 2>&1)
ok "$(says "$out" "PHASE BOUNDARY")" "fires when the last task in a phase is ticked" "$out"
ok "$(says "$out" "Phase 1")" "names the phase that ended" "$out"
teardown

fixture; plan_with ""
sh "$ROOT/scripts/phase-boundary.sh" >/dev/null 2>&1
plan_with "p1t1 p1t2"
sh "$ROOT/scripts/phase-boundary.sh" >/dev/null 2>&1
out=$(sh "$ROOT/scripts/phase-boundary.sh" 2>&1)
ok "$(empty "$out")" "idempotent - does not re-announce the same boundary" "$out"
teardown

fixture; plan_with "p1t1 p1t2 p2t1 p2t2"
out=$(sh "$ROOT/scripts/phase-boundary.sh" 2>&1)
ok "$(says "$out" "wrap")" "end of plan sends you to wrap, not to a successor" "$out"
ok "$(says "$out" "Do NOT spawn")" "end of plan explicitly forbids spawning" "$out"
teardown

fixture; plan_with ""
sh "$ROOT/scripts/phase-boundary.sh" >/dev/null 2>&1
plan_with "p1t1 p1t2"
sh "$ROOT/scripts/phase-boundary.sh" >/dev/null 2>&1; code=$?
ok "$([ "$code" -eq 2 ] && echo yes || echo no)" "a boundary exits 2 - stdout on exit 0 never reaches the model" "$code"
teardown

fixture; plan_with ""
sh "$ROOT/scripts/phase-boundary.sh" >/dev/null 2>&1
plan_with "p1t1 p1t2"
out=$(sh "$ROOT/scripts/phase-boundary.sh" 2>/dev/null)
ok "$(empty "$out")" "the directive goes to stderr, not stdout" "$out"
teardown

fixture; plan_with ""
sh "$ROOT/scripts/phase-boundary.sh" >/dev/null 2>&1
plan_with "p1t1 p1t2"
sh "$ROOT/scripts/phase-boundary.sh" >/dev/null 2>&1
sh "$ROOT/scripts/phase-boundary.sh" >/dev/null 2>&1; code=$?
ok "$([ "$code" -eq 0 ] && echo yes || echo no)" "the second pass exits 0 so the session can actually end" "$code"
teardown

fixture; plan_with "p1t1 p1t2 p2t1 p2t2"
sh "$ROOT/scripts/phase-boundary.sh" >/dev/null 2>&1; code=$?
ok "$([ "$code" -eq 2 ] && echo yes || echo no)" "end of plan exits 2 as well" "$code"
sh "$ROOT/scripts/phase-boundary.sh" >/dev/null 2>&1; code=$?
ok "$([ "$code" -eq 0 ] && echo yes || echo no)" "end of plan does not block a second time" "$code"
teardown

# The context boundary: mid-phase, over budget, the session still ends.
fixture; plan_with ""; transcript_with 500000
sh "$ROOT/scripts/phase-boundary.sh" >/dev/null 2>&1
plan_with "p1t1"
out=$(sh "$ROOT/scripts/phase-boundary.sh" 2>&1); code=$?
ok "$(says "$out" "CONTEXT BOUNDARY")" "fires mid-phase when context crosses the budget" "$out"
ok "$([ "$code" -eq 2 ] && echo yes || echo no)" "the context boundary exits 2" "$code"
ok "$(says "$out" "PART DONE")" "tells the handoff the phase is unfinished" "$out"
ok "$([ -f .flow/handoff-pending ] && echo yes || echo no)" "leaves the pending marker for /flow:loop"
teardown

fixture; plan_with ""; transcript_with 50000
sh "$ROOT/scripts/phase-boundary.sh" >/dev/null 2>&1
plan_with "p1t1"
out=$(sh "$ROOT/scripts/phase-boundary.sh" 2>&1)
ok "$(empty "$out")" "silent mid-phase when context is under the budget" "$out"
teardown

fixture; plan_with "p1t1 p1t2"
printf '## Phase 9 — gone\n' > .flow/phase
out=$(sh "$ROOT/scripts/phase-boundary.sh" 2>&1)
ok "$(says "$out" "PHASE BOUNDARY")" "a stale recorded phase still resolves to a boundary" "$out"
teardown

fixture; plan_with ""
rm -f .flow/current
out=$(sh "$ROOT/scripts/phase-boundary.sh" 2>&1)
ok "$(empty "$out")" "silent when no effort is live" "$out"
teardown

fixture
printf '# no phases here\n\n- [ ] loose task\n' > docs/demo-plan.md
out=$(sh "$ROOT/scripts/phase-boundary.sh" 2>&1)
ok "$(empty "$out")" "silent on a plan with no phase headings" "$out"
teardown

fixture; plan_with ""
rm -f docs/demo-plan.md
out=$(sh "$ROOT/scripts/phase-boundary.sh" 2>&1)
ok "$(empty "$out")" "silent when the plan file is missing" "$out"
teardown

# ---------------------------------------------------------------------------
echo "context-budget.sh"
# ---------------------------------------------------------------------------

fixture; plan_with ""; transcript_with 50000
out=$(sh "$ROOT/scripts/context-budget.sh" 2>&1)
ok "$(empty "$out")" "silent below the backstop" "$out"
teardown

fixture; plan_with ""; transcript_with 500000
out=$(sh "$ROOT/scripts/context-budget.sh" 2>&1)
ok "$(says "$out" "CONTEXT BACKSTOP")" "fires above the backstop" "$out"
ok "$(says "$out" "sized wrong")" "says the phase was mis-sized, not just that context is big" "$out"
teardown

fixture; plan_with ""; transcript_with 500000
sh "$ROOT/scripts/context-budget.sh" >/dev/null 2>&1; code=$?
ok "$([ "$code" -eq 2 ] && echo yes || echo no)" "the backstop exits 2 so the model is actually told" "$code"
sh "$ROOT/scripts/context-budget.sh" >/dev/null 2>&1; code=$?
ok "$([ "$code" -eq 0 ] && echo yes || echo no)" "it fires once per session, never blocking the stop forever" "$code"
teardown

fixture; plan_with ""; transcript_with 500000
out=$(sh "$ROOT/scripts/context-budget.sh" 2>/dev/null)
ok "$(empty "$out")" "the backstop writes to stderr, not stdout" "$out"
teardown

# 250K is the default, and it is what an unset ground rule resolves to.
fixture
printf '# Demo\n\n## Phase 1 — first\n\n- [ ] task 1\n' > docs/demo-plan.md
transcript_with 260000
out=$(sh "$ROOT/scripts/context-budget.sh" 2>&1)
ok "$(says "$out" "CONTEXT BACKSTOP")" "the default backstop is 250K, not 400K" "$out"
teardown

fixture
printf '# Demo\n\n## Phase 1 — first\n\n- [ ] task 1\n' > docs/demo-plan.md
transcript_with 240000
out=$(sh "$ROOT/scripts/context-budget.sh" 2>&1)
ok "$(empty "$out")" "and it is silent just below 250K" "$out"
teardown

fixture; plan_with ""; transcript_with 500000
rm -f .flow/current
out=$(sh "$ROOT/scripts/context-budget.sh" 2>&1)
ok "$(empty "$out")" "silent when no effort is live" "$out"
teardown

fixture; plan_with ""
enc=$(pwd -W 2>/dev/null || pwd); enc=$(printf '%s' "$enc" | sed 's#[:/\\]#-#g')
rm -rf "$HOME/.claude/projects/$enc"
out=$(sh "$ROOT/scripts/context-budget.sh" 2>&1)
ok "$(empty "$out")" "silent when the transcript cannot be located" "$out"
teardown

fixture; plan_with ""; transcript_with 200000
out=$(sh "$ROOT/scripts/context-budget.sh" 2>&1)
ok "$(says "$out" "CONTEXT BACKSTOP")" "honours the plan's own backstop over the default" "$out"
teardown

# ---------------------------------------------------------------------------
echo "guard-image-read.sh"
# ---------------------------------------------------------------------------

payload() { printf '{"tool_name":"Read","tool_input":{"file_path":"%s"}}' "$1"; }

fixture; plan_with ""
dd if=/dev/zero of=big.png bs=1024 count=200 2>/dev/null
out=$(payload "$WORK/big.png" | sh "$ROOT/scripts/guard-image-read.sh" 2>&1); code=$?
ok "$([ "$code" -eq 2 ] && echo yes || echo no)" "blocks a large image read with exit 2" "exit $code"
ok "$(says "$out" "touch .flow/see")" "names the escape hatch in the block message" "$out"
teardown

fixture; plan_with ""
dd if=/dev/zero of=big.png bs=1024 count=200 2>/dev/null
touch .flow/see
out=$(payload "$WORK/big.png" | sh "$ROOT/scripts/guard-image-read.sh" 2>&1); code=$?
ok "$([ "$code" -eq 0 ] && echo yes || echo no)" "the escape hatch permits the read" "exit $code"
ok "$([ -f .flow/see ] && echo no || echo yes)" "the marker is consumed by the read it permits"
teardown

fixture; plan_with ""
dd if=/dev/zero of=small.png bs=1024 count=8 2>/dev/null
out=$(payload "$WORK/small.png" | sh "$ROOT/scripts/guard-image-read.sh" 2>&1); code=$?
ok "$([ "$code" -eq 0 ] && echo yes || echo no)" "small images pass through" "exit $code"
teardown

fixture; plan_with ""
dd if=/dev/zero of=notes.md bs=1024 count=200 2>/dev/null
out=$(payload "$WORK/notes.md" | sh "$ROOT/scripts/guard-image-read.sh" 2>&1); code=$?
ok "$([ "$code" -eq 0 ] && echo yes || echo no)" "non-images pass through whatever their size" "exit $code"
teardown

fixture
dd if=/dev/zero of=big.png bs=1024 count=200 2>/dev/null
rm -f .flow/current
out=$(payload "$WORK/big.png" | sh "$ROOT/scripts/guard-image-read.sh" 2>&1); code=$?
ok "$([ "$code" -eq 0 ] && echo yes || echo no)" "inert when no effort is live" "exit $code"
teardown

# ---------------------------------------------------------------------------
echo "run-gated.sh"
# ---------------------------------------------------------------------------

fixture; plan_with ""
out=$(sh "$ROOT/scripts/run-gated.sh" sh -c 'i=0; while [ $i -lt 500 ]; do echo "noise line $i"; i=$((i+1)); done' 2>&1); code=$?
ok "$([ "$code" -eq 0 ] && echo yes || echo no)" "passes the command's exit code through on success" "exit $code"
ok "$(says "$out" "PASS")" "a green run reports pass" "$out"
ok "$([ "$(printf '%s' "$out" | wc -l)" -lt 8 ] && echo yes || echo no)" "500 lines of green output collapse to a few" "$(printf '%s' "$out" | wc -l) lines"
ok "$([ -n "$(ls .flow/logs/ 2>/dev/null)" ] && echo yes || echo no)" "the full log is kept on disk"
teardown

fixture; plan_with ""
out=$(sh "$ROOT/scripts/run-gated.sh" sh -c 'echo "error: the thing broke"; exit 3' 2>&1); code=$?
ok "$([ "$code" -eq 3 ] && echo yes || echo no)" "passes a failing exit code through" "exit $code"
ok "$(says "$out" "FAIL")" "a red run reports fail" "$out"
ok "$(says "$out" "the thing broke")" "a red run shows the actual failing line" "$out"
teardown

fixture; plan_with ""
out=$(sh "$ROOT/scripts/run-gated.sh" 2>&1); code=$?
ok "$([ "$code" -eq 64 ] && echo yes || echo no)" "usage error with no command" "exit $code"
teardown

# ---------------------------------------------------------------------------
echo "session-state.sh"
# ---------------------------------------------------------------------------

fixture; plan_with ""
out=$(sh "$ROOT/scripts/session-state.sh" 2>&1)
ok "$(says "$out" "0 done, 4 remaining")" "counts tick correctly with nothing ticked" "$out"
ok "$([ "$(printf '%s' "$out" | grep -c 'done,')" -eq 1 ] && echo yes || echo no)" "the count is one line, not two (grep -c prints 0 AND exits 1)" "$out"
ok "$(says "$out" "Phase 1")" "reports the phase" "$out"
ok "$([ -f .flow/phase ] && echo yes || echo no)" "claims the phase for this session"
teardown

fixture; plan_with "p1t1 p1t2 p2t1"
out=$(sh "$ROOT/scripts/session-state.sh" 2>&1)
ok "$(says "$out" "3 done, 1 remaining")" "counts tick correctly with some ticked" "$out"
teardown

fixture; plan_with ""; transcript_with 250000
out=$(sh "$ROOT/scripts/session-state.sh" 2>&1)
ok "$(says "$out" "context:")" "reports context against the budget when a transcript exists" "$out"
teardown

fixture; plan_with ""
rm -f .flow/current
out=$(sh "$ROOT/scripts/session-state.sh" 2>&1)
ok "$(empty "$out")" "silent when no effort is live" "$out"
teardown

fixture; plan_with "p1t1 p1t2"
out=$(sh "$ROOT/scripts/session-state.sh" 2>&1)
ok "$(says "$out" "Phase 2")" "reports the phase of the NEXT task, not always Phase 1" "$out"
teardown

fixture; plan_with "p1t1 p1t2 p2t1 p2t2"
out=$(sh "$ROOT/scripts/session-state.sh" 2>&1)
ok "$(says "$out" "complete")" "handles a fully ticked plan without printing 'unknown'" "$out"
teardown

# ---------------------------------------------------------------------------
echo "the chain, end to end"
# ---------------------------------------------------------------------------

fixture; plan_with ""
sh "$ROOT/scripts/session-state.sh" >/dev/null 2>&1     # session 1 claims phase 1
plan_with "p1t1 p1t2"                                    # session 1 finishes phase 1
sh "$ROOT/scripts/phase-boundary.sh" >/dev/null 2>&1
ok "$(says "$(session_phase_of)" "Phase 1")" "the session still owns the phase it finished" "$(session_phase_of)"
ok "$([ -f .flow/handoff-pending ] && echo yes || echo no)" "a pending marker is left for /flow:loop to read"
sh "$ROOT/scripts/write-handoff-spine.sh" >/dev/null 2>&1
ok "$(says "$(cat HANDOFF-demo.md)" "owned:** ## Phase 1")" "the handoff names the phase that ended the session" "$(grep owned HANDOFF-demo.md)"
sh "$ROOT/scripts/session-state.sh" >/dev/null 2>&1      # session 2 starts
ok "$(says "$(session_phase_of)" "Phase 2")" "the successor claims the next phase" "$(session_phase_of)"
ok "$([ -f .flow/handoff-pending ] && echo no || echo yes)" "the successor clears the pending marker"
ok "$([ "$(cat .flow/session-count)" = "2" ] && echo yes || echo no)" "the chain counter advances" "$(cat .flow/session-count)"
out=$(sh "$ROOT/scripts/phase-boundary.sh" 2>&1)
ok "$(empty "$out")" "the successor does not immediately re-fire the boundary" "$out"
teardown

# ---------------------------------------------------------------------------
echo "the manifest"
# ---------------------------------------------------------------------------

# The harness executes a hook command directly, so the exec bit is part of the
# contract. Every test above invokes `sh script.sh`, which passes with or without
# it - only this check sees the difference between a hook that runs and one that
# fails with Permission denied.
for rel in $(grep -o 'scripts/[A-Za-z0-9_.-]*' "$ROOT/hooks/hooks.json" | sort -u); do
  ok "$([ -x "$ROOT/$rel" ] && echo yes || echo no)" "$rel is executable" "$(ls -l "$ROOT/$rel" 2>&1)"
done

# run-gated.sh is not a hook, but plans name it as their build command and run it
# the same way.
ok "$([ -x "$ROOT/scripts/run-gated.sh" ] && echo yes || echo no)" "scripts/run-gated.sh is executable"

# ---------------------------------------------------------------------------
printf '\n%s passed, %s failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ] || exit 1
