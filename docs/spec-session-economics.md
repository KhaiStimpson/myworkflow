# Spec — session economics

Status: ready-for-agent · Written: 2026-08-26 · Repo: `myworkflow` @ `a6c2a47`

Supersedes the cost figures in [`session-economics-findings.md`](session-economics-findings.md)
and `HANDOFF-session-economics.md`. Both were re-derived from `~/.claude/projects/*/*.jsonl` on
2026-08-26; the measurement layer reproduced exactly, the savings model did not. See
Implementation Decision D0 for the corrections and what they change.

## Problem Statement

My long implementation sessions cost far more than the work in them warrants, and I can feel it
without being able to point at the cause. A route-2 effort — plan file, loop prompt, twenty-odd
tickets — runs as a single thread that grows all day. By the last ticket I am paying to re-read
the first fifteen on every turn, and the model is reasoning about a transcript that is mostly
irrelevant to the task in front of it.

Two things follow, and I dislike both. The bill is real money on work that got no better for the
spend. And when the thread finally fills, it auto-compacts — which is the worst moment for it to
happen, because compaction is lossy and it fires on the token counter's schedule rather than on a
task boundary. I would rather hand off to a fresh session at a point I choose than be compacted at
a point I do not.

I also cannot see any of this while it is happening. There is no signal in the session that says
"you are at 700K and climbing"; I find out afterwards, from the invoice.

## Solution

The flow gains a **context budget** it actively manages, instead of a context ceiling it
eventually hits.

**One phase, one session.** When the loop ticks the last task in a phase, it writes the handoff,
commits, and stops. `/flow:loop` then continues the next phase in a **fresh background agent on
clean context**, which reads the plan and the handoff and nothing else. The plan file is already
the state; this makes the session genuinely disposable, so an effort becomes a chain of short cheap
sessions rather than one long expensive one. Auto-compaction stops being the thing that ends a
session — a phase boundary is.

For that to work, phases have to be sized to fit a session, which today nothing enforces. So
`/flow:plan` gains a sizing constraint alongside its existing dependency ordering. And because a
single runaway task can still blow a session from inside one phase, a context check runs as a
backstop — not as the trigger.

Alongside that, the two measured leaks get plugged at the source: image reads that put 200K-char
payloads into the transcript, and test-output dumps that put build noise there. Both are filtered
to a summary, with the full artefact left on disk to read deliberately if it is ever needed.

And the whole thing becomes visible: the session-start hook reports where context stands and what
the budget is, so the number is in front of me while the work is happening rather than on a bill
afterwards.

## User Stories

1. As a developer running a long effort, I want each phase of the plan to run in its own session,
   so that the boundary is a meaningful unit of work rather than an arbitrary token count.
2. As a developer, I want the handoff to fire when a phase completes rather than mid-task, so that
   the next session never inherits half-finished work.
3. As a developer, I want the next session to start from the plan and the handoff only, so that I
   stop paying to re-read a transcript whose conclusions are already written down.
4. As a developer, I want to know from the plan how many sessions an effort will take, so that its
   cost is predictable before I start rather than discovered afterwards.
5. As a developer writing a plan, I want phases sized to fit one session, so that "one phase, one
   session" is a real guarantee and not an aspiration.
6. As a developer, I want a phase that is too large to be flagged when the plan is written, so that
   I can split it before it costs me rather than after.
7. As a developer, I want a runaway task to be caught even mid-phase, so that a single pathological
   iteration cannot blow the budget that phase boundaries were supposed to protect.
8. As a developer, I want to see the live context size at session start, so that I know whether I
   am beginning fresh or resuming something already large.
9. As a developer, I want the handoff written automatically at the phase boundary, so that stopping
   is never a decision I have to remember to act on.
10. As a developer, I want the successor agent spawned on fresh context, never forked, so that
    convention A1 is not quietly eroded by this feature.
11. As a developer, I want one successor agent carrying the plan forward, not one agent per phase
    running concurrently, so that the topology Anthropic's docs steer away from for sequential
    dependent work is not what I build.
12. As a developer running a UI effort, I want screenshots referenced by path rather than read into
    context by default, so that a review pass does not cost 200K characters per look.
13. As a developer, I want to be able to read a screenshot deliberately when I actually need to see
    it, so that the discipline is a default rather than a prohibition.
14. As a developer, I want test and build output filtered to failures and a pass count, so that a
    green run costs almost nothing to observe.
15. As a developer, I want the full unfiltered output kept on disk, so that filtering never
    destroys the thing I need when something breaks.
16. As a developer, I want the model choice for loop iterations recorded in the plan's ground
    rules, so that an effort's cost posture is a decision rather than an accident of whatever was
    selected that day.
17. As a developer, I want the true cost multiplier stated honestly in the docs, so that I am not
    making decisions against a number that does not reproduce.
18. As a developer, I want the measurement script kept in the repo, so that re-deriving these
    figures costs minutes rather than a research pass.
19. As a developer, I want to re-run the measurement after the change lands, so that I can tell
    whether it actually worked instead of assuming it did.
20. As a developer, I want the whole feature to cost nothing in a repo with no live effort, so that
    installing the plugin does not tax unrelated work.
21. As a developer, I want the phase-boundary stop to be overridable with one word, so that I can
    tell it to carry straight on when the next phase is small or the effort is nearly finished.
22. As a developer, I want the successor agent's name reported when it spawns, so that I can find
    it and watch it.
23. As a developer, I want each session in the chain to commit its work before stopping, so that a
    handoff never depends on uncommitted state surviving.
24. As a developer, I want the handoff to record which phase ended it, so that the chain of
    sessions is visible in retrospect.

## Implementation Decisions

### D0 — The corrected economics (this supersedes the prior figures)

Re-derivation on 2026-08-26 confirmed every measurement and refuted two derived claims.

**Reproduced exactly:** turns, peak context, cache reads, cache writes, output tokens, zero
subagents across all six sessions, and the 998K → auto-compact → 275K climb in `4c15e762`.

**Refuted — model attribution.** The table labelled "Cost as run (Opus 5)" is wrong twice. The
Opus sessions ran on `claude-opus-4-8`, not Opus 5. And three of the six already ran on
`claude-sonnet-5` but were priced at Opus rates:

| Session | Model actually used | Actual | As previously stated |
|---|---|---|---|
| andrew-crm `4c15e762` | claude-opus-4-8 | $427 | $427 |
| andrew-crm `eff1e858` | claude-opus-4-8 (+22 sonnet) | $373 | $378 |
| dump-debugger `ef33c968` | **claude-sonnet-5** | $162 | $270 |
| sqlviewer `aa0efe15` | **claude-sonnet-5** | $83 | $138 |
| sqlviewer `54a4e45c` | **claude-sonnet-5** | $78 | $130 |
| andrew-crm `68f43899` | claude-opus-4-8 | $101 | $101 |
| **Total** | | **$1,224** | $1,444 |

**Refuted — the savings model.** Opus and Sonnet 5 differ by a flat 1.67× on every token class
(input 5/3, cache write 6.25/3.75, cache read 0.5/0.3, output 25/15), not 2.5×. Because half the
corpus was already Sonnet, the realizable multiplier from a model switch is **1.41×**. Combined
with splitting at 1.9×, the estimate falls from **4.7× ($1,444 → $307)** to **≈2.7×
($1,224 → $457)**.

**This re-ranks the work.** Splitting is the dominant lever and the model switch is the minor one —
the reverse of the prior ordering. The ranks below are renumbered accordingly.

**Narrowed — screenshot bloat.** Confirmed but mis-scoped. `aa0efe15` has 63 image reads totalling
7.68M chars, largest 229,852 (the "230K" figure is exact), amounting to **96% of that session's
entire tool-result payload**. `54a4e45c` has **zero**. The leak is one session, not "sqlviewer",
and the previously stated "119 calls averaging 66K" does not reproduce. It is still worth fixing —
a single session where 96% of observed bytes are screenshots is a real pattern — but it is a
smaller and narrower prize than stated.

**Unchanged and load-bearing:** ~81% of spend is cache reads, and zero subagents ran in any
measured session.

### D1 — Two seams, deliberately

This repo has no test suite and no test runner. Behaviour splits across two seams and the spec
treats them differently:

- **Seam 1 — `scripts/*.sh`, invoked as processes.** The only executable code. Contract is
  stdin/stdout plus filesystem mutation against a git working tree. Machine-verifiable.
- **Seam 2 — skill and template markdown.** Prose that shapes model behaviour. Not unit-testable;
  verified by reading and by behavioural runs.

**All new logic goes in seam 1 wherever it can.** Where a behaviour genuinely cannot — the wording
of a stop-and-hand-off instruction, screenshot discipline in a skill — it goes in seam 2 and is
named as such. New seams beyond these two are not introduced.

### D2 — Rank 1: one phase, one session (the dominant lever)

**The trigger is the phase boundary, not a token count.** When the loop ticks the last unchecked
task under a `## Phase` heading, it commits, updates the handoff, records which phase it finished,
and stops. The next phase runs in a fresh session (D3).

Chosen over a pure context threshold because the boundary is semantic rather than arbitrary: the
successor starts on a coherent unit of work, the handoff says "phase 2 complete" instead of "we hit
350K mid-task", the session count is knowable from the plan before the effort starts (story 4), and
it reuses state the plan already carries — `scripts/session-state.sh` already greps `^## Phase`.

**The measured basis for phase sizing.** The specimen `4c15e762` re-segmented by loop iteration,
costed at Opus rates:

| Iter | ctx at end | cost | | Iter | ctx at end | cost |
|---|---|---|---|---|---|---|
| 1 | 97,585 | $6.51 | | 13 | 785,787 | **$123.77** |
| 5 | 213,063 | $7.21 | | 14 | 880,770 | $57.38 |
| 7 | 262,796 | $8.14 | | 16 | 992,441 | $48.37 |
| 8 | 340,357 | $17.69 | | **17** | **89,315** ← auto-compact | **$7.24** |
| 10 | 469,018 | $12.40 | | 20 | 187,752 | $5.14 |

Iterations 17–20, running after the auto-compact dropped context to 89K, cost $4.55–$7.24 — the
same as iterations 1–7. Iterations 13–16 cost $25–$124 for comparable work. The knee is at
**~250–300K**: below it an iteration costs $3–8, above it cost escalates fast. Iterations 1–7
reached 263K and post-compact 17–21 reached 264K in five, so **a session comfortably holds about
five to seven tasks.**

### D2a — `/flow:plan` must size phases, not just order them

Today `skills/plan/SKILL.md` orders phases by dependency alone — "phases in dependency order, each
with a one-line goal you could judge" — and nothing constrains how many tasks a phase holds. Under
D2 that is now load-bearing: a three-task phase wastes a fresh session's warmup, and a fourteen-task
phase sails past 700K and gets auto-compacted anyway, which is the exact failure this spec exists to
remove.

So `/flow:plan` gains a sizing constraint: **target five to seven tasks per phase**, derived from
D2's measurements. Where dependency ordering and sizing conflict, dependency wins and the oversized
phase is split into `Phase 3a` / `Phase 3b` at the least-coupled seam rather than being reordered.
A phase that cannot be split below the ceiling is flagged in the plan when it is written (story 6),
not discovered mid-loop.

This is seam 2 — prose in the plan skill and a note in `templates/plan.md`, whose skeleton currently
shows two tasks per phase and should show a realistic five.

### D2b — The context check, demoted to a backstop

A phase boundary cannot catch a runaway *task*. In the table above, iteration 13 burned 257 turns
and $123.77 inside a single iteration — no phase boundary would have interrupted it. So the context
check survives, as a safety net rather than as the trigger.

`scripts/context-budget.sh`, wired to a hook that fires after each iteration:

- Below the backstop: silent. A hook that prints nothing is free.
- At or above it: emit the directive to finish the current task, commit, update the handoff, and
  stop the loop — the same stop D2 performs, fired early and out of band.

Backstop default **400K**, overridable in the plan's ground rules. Deliberately set above the knee
and above the peak of the cheapest measured session: it should almost never fire, and a session that
trips it is evidence that D2a's sizing was wrong for that phase, which is worth surfacing in the
handoff.

**Locating the transcript is solved and does not depend on `transcript_path`.** Verified locally on
2026-08-26: the live session's transcript is the most recently modified `*.jsonl` in the cwd-derived
project directory under `~/.claude/projects/`, and its last assistant `usage` record yields live
context directly. Measured 78,573 tokens on a running session this way. The hook payload's
`transcript_path` field is used when present and the mtime scan is the fallback, so the detector has
no unverified dependency.

**Live context is `input_tokens + cache_read_input_tokens + cache_creation_input_tokens`** from the
last assistant `usage` record. Confirmed present on live records.

One word from the user overrides either stop (story 21) — seam 2, in the loop prompt.

### D3 — Rank 2: `/flow:loop` route B becomes the default continuation path

Route B already spawns one background agent on fresh context; today it is gated behind `.flow/fog`.
That gate widens: route B is also the path taken when a session stops at a phase boundary.

Route selection becomes: **A** when starting fresh with no fog and no completed phase behind it;
**B** when a fog marker exists, *or* when the handoff records a phase-boundary stop. The successor
is spawned exactly as route B already does — `subagent_type: general-purpose`,
`run_in_background: true`, fresh context, never forked (story 10, convention A1).

**One agent at a time, carrying the plan forward.** Each session runs one phase and spawns one
successor; phases run in sequence, never concurrently. This is the sequential chain, not the
rejected one-agent-per-phase fan-out — the distinction is that phases here run one after another
against shared committed state, rather than in parallel against a shared context they cannot see
(story 11).

The rejection of one-background-agent-per-phase stands and is not reopened. Anthropic's subagents
documentation places multi-phase shared-context work under *use your main conversation*, and the
agent-teams documentation states that sequential work with many dependencies is better served by a
single session. Cited in `research/long-running-claude-code-session-economics.md`.

**Ordering constraint, carried forward from the prior handoff and still binding:** the handoff must
be load-bearing *before* sessions become disposable. D2's handoff write and D3's spawn land
together, or D2 lands first; D3 must not land alone. D2a lands with or before D2, since
phase-per-session without phase sizing is worse than no change at all.

`templates/loop-prompt.md` gains a phase-boundary stop clause alongside its existing anatomy — its
`If all items are checked, stop the loop` line becomes a two-level stop: end of phase hands off, end
of plan terminates (seam 2). The successor's spawn reports its agent name (story 22).

### D4 — Rank 3: output filters

Two filters, both scripts on seam 1, both preserving the full artefact on disk (story 15).

- **Image reads.** A `Read` of `.png`/`.jpg`/`.jpeg`/`.webp` during a live effort is reduced to
  path, dimensions, and byte size rather than the full payload. Deliberate reads stay available
  (story 13) — the filter is a default, not a prohibition, and the escape hatch must be documented
  where it will be found.
- **Build and test output.** Reduced to failures plus a pass/fail count; the full log is written
  under `.flow/logs/` and referenced by path.

Both are inert when no effort is live (story 20).

### D5 — Rank 4: model posture, demoted

The plan's ground rules gain an explicit model line for loop iterations. This is now a **1.41×**
lever, not 2.5×, and the spec says so wherever the number appears (story 17).

The skills already declare `model: sonnet` in frontmatter; the *sessions* did not. This decision is
about the session and loop-iteration model, not the skill frontmatter, which needs no change.

The prior handoff's blocking question — "is Sonnet 5 acceptable for `/flow:work` slices, or only
for the loop runner?" — is **resolved by evidence rather than by preference**: three of the six
measured sessions, including all of `dump-debugger` and `sqlviewer`, already ran entirely on
Sonnet 5 and produced shipped work. The posture is therefore per-effort and recorded in the plan,
defaulting to Sonnet for loop iterations.

### D6 — The measurement script becomes a repo artefact

`scripts/measure-sessions.sh` (or a `.py` alongside it) is committed, so the figures in D0 are
re-derivable in minutes (story 18) and the change can be measured after it lands (story 19). It is
a developer tool, not a hook — it never runs automatically and costs nothing when unused.

Re-running it after the effort completes is the acceptance measurement for the whole spec.

### D7 — `.gitignore`

The repo has none. `HANDOFF-*.md` is untracked by absence rather than by rule, which is fragile,
and D4 introduces `.flow/logs/`. A `.gitignore` covering `.flow/` and `HANDOFF-*.md` lands with
this effort. Convention P8 asks for this independently.

### D8 — The research file is committed

`docs/research/long-running-claude-code-session-economics.md` is the citation backing for D0 and D3
and is a design record, which per the repo's own stated principle argues for committing rather than
leaving untracked. It is committed as-is; its UNVERIFIED claims stay marked UNVERIFIED and none of
them is promoted to fact anywhere in this spec.

## Testing Decisions

**What makes a good test here:** it invokes a script as a process against a fixture and asserts only
the external contract — stdout, exit code, and file mutations. It never asserts on internal shell
functions or on prose wording. A test that breaks when a message is reworded is testing the wrong
thing.

**Seam 1 — machine-verified.** Each new script is exercised against a throwaway git repo fixture.
Cases per script:

- Phase-boundary detection (D2): given a fixture plan, correctly identifies the last unchecked task
  in a phase, distinguishes end-of-phase from end-of-plan, and stays silent mid-phase. Edge cases
  worth fixtures: a phase with every box already ticked, a plan with one phase only, an unchecked
  task in an *earlier* phase than the current one, and a `## Phase` heading with no tasks under it.
- `context-budget.sh` (D2b): silent below the backstop; directive at or above it; silent exit 0 when
  `.flow/current` is absent; silent exit 0 when the transcript cannot be located. Fixtures are
  synthetic `.jsonl` files with a single crafted `usage` record, which makes every case cheap to
  construct.
- The D4 filters: a payload over threshold is summarised, one under it passes through, the full
  artefact exists on disk afterwards, and both are inert with no live effort.
- `measure-sessions.sh`: run against a synthetic transcript with known token counts and assert the
  arithmetic. This is the one piece of real logic in the repo whose correctness is checkable
  independently of Claude Code, and D0 exists because it was worth checking.

**Prior art:** none in-repo — this is the first test infrastructure here. The closest existing model
is the scripts themselves: `session-state.sh` and `write-handoff-spine.sh` already have exactly the
"read `.flow/current`, read git, print or mutate" shape these tests assume, so they should be
retro-fitted with the same fixture tests once the harness exists.

**Seam 2 — human-verified, and named as such.** The loop-prompt two-level stop, the route-B
widening, D2a's phase sizing, the screenshot-discipline wording, and the ground-rules model line are
verified by one behavioural run of a real route-2 effort with at least three phases, plus a read of
the diff. The acceptance evidence is that the effort completes across a chain of sessions with the
plan file as its only carried state, that no session auto-compacted, and that D6's script re-run
shows the cost actually fell.

**The sizing check is itself a measurement, not an assertion.** After the behavioural run, D6's
script reports peak context per session. If phases sized to D2a's five-to-seven target are landing
well under or well over the ~250–300K knee, the target is wrong and gets corrected in the plan skill
— the number is a starting estimate from one specimen, not a law.

**Explicitly not tested:** whether the model obeys the prose. That is what the behavioural run and
`/flow:eyes` are for.

## Out of Scope

- **One background agent per phase.** Rejected on documented evidence (D3). Not reopened.
- **Parallel fan-out across tasks.** It buys wall-clock, not tokens. If it is ever built it is
  bought for speed and said so out loud.
- **Narrowing convention A1 to permit forked non-reviewers** (the prior "idea B5"). A1's value is
  that it is absolute. Flagged, not decided, and not decided here either.
- **Headless `claude -p` as the continuation mechanism.** Considered and set aside: it has no
  interactive stop-and-ask path, which the loop prompt's safety clause depends on. Background agent
  on fresh context is the chosen mechanism.
- **Any change to skill frontmatter `model:` declarations.** Already `sonnet`; D5 concerns the
  session model.
- **Retro-fitting the entire repo with tests.** The harness lands and covers new scripts; the two
  existing scripts are a follow-on.
- **Orchestrator integration.** Separate private repo; the routing model stays deliberately aligned
  but nothing here reaches into it.

## Further Notes

**Doc-URL drift.** `docs.anthropic.com/en/docs/claude-code/*` now 404s; Claude Code docs live at
`code.claude.com/docs/en/*`. Existing links in this repo may be dead and should be checked
opportunistically.

**Account session limit.** The `flow:researcher` run that produced the citation file died on the
account session limit (resets 10am Australia/Brisbane) after finishing its report. Any re-run of a
comparable research pass will hit the same wall. Agent id `adea735503bd5607b`.

**A counting note.** User-message totals in the prior findings (46 for `4c15e762`) do not reproduce
under a stricter definition that excludes meta and tool-result turns; that count is 25. This makes
the turn-amplification argument stronger, not weaker — 1,583 assistant turns from 25 real user
messages — but the two numbers should not be cited interchangeably.

**Convention alignment.** This spec exercises R3 (cost-consciousness volunteered), P5 (the handoff
carries state between sessions), A1 (fresh context, never forked), P1 (the plan is the unit of
execution), and P8 (finish the job — the `.gitignore`). D5 resolves the T1 question for this repo
by recording the posture in the plan rather than assuming one.
