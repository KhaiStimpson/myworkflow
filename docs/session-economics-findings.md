# The Million-Token Loop — findings

Workflow review of long-running Claude Code implementation sessions.
Investigation date: 2026-08-22. Repo: `myworkflow` @ `a6c2a47`.

Companion artifact: <https://claude.ai/code/artifact/c3577d5f-1428-40ab-b90a-74473ada20f8>
Citation backing: [`research/long-running-claude-code-session-economics.md`](research/long-running-claude-code-session-economics.md)

**Question asked:** are long implementation sessions wasting tokens by doing all the work in one
thread instead of spawning a background agent per phase?

**Answer:** the sessions are badly inefficient and the measurements confirm it — but a background
agent per phase is the wrong fix, and is the one topology Anthropic's docs explicitly steer away
from for sequential dependent work. The right fix is fresh sessions with the plan file as state,
which `skills/loop/SKILL.md` already half-implements.

---

## 1. Evidence

Parsed from assistant-message `usage` records in `~/.claude/projects/*/*.jsonl`. All sessions
over 400 KB were measured; the six largest are below.

| Session | Turns | User msgs | Peak ctx | Cache reads | Cache writes | Output | Subagents |
|---|---|---|---|---|---|---|---|
| andrew-crm `4c15e762` | 1,583 | 46 | 998,029 | 665,516,673 | 7,357,310 | 1,913,800 | 0 |
| andrew-crm `eff1e858` | 1,396 | 26 | 777,707 | 577,471,730 | 9,212,264 | 1,252,358 | 0 |
| dump-debugger `ef33c968` | 1,233 | 12 | 734,048 | 482,420,669 | 2,055,635 | 626,376 | 0 |
| sqlviewer `aa0efe15` | 810 | 5 | 557,607 | 235,681,013 | 1,180,523 | 524,673 | 0 |
| sqlviewer `54a4e45c` | 735 | 8 | 510,735 | 218,686,626 | 1,565,202 | 431,066 | 0 |
| andrew-crm `68f43899` | 561 | 12 | 479,944 | 152,732,172 | 1,149,681 | 714,858 | 0 |
| **Total** | **6,318** | 109 | — | **2.33B** | 22.5M | 5.46M | **0** |

**Zero subagents across all six sessions.** `skills/work/SKILL.md` correctly spawns `eyes` and
`fresh-eyes`, but none of these sessions ran through `/flow:work`.

### 1.1 The specimen: andrew-crm `4c15e762`

1,583 assistant turns generated from **46 user messages**. The session was started with
`/loop "Implement the next ready ticket from the AndrewCrm.Web front-end standards map…"` and the
bundled `/loop` skill re-fired that same prompt **22 times inside the same transcript**.

Context at the start of each loop iteration (each point is a `ScheduleWakeup` call):

| Iter | Turn | Context | Iter | Turn | Context |
|---|---|---|---|---|---|
| 1 | 100 | 97,585 | 12 | 741 | 544,078 |
| 2 | 166 | 127,189 | 13 | 998 | 785,787 |
| 3 | 217 | 153,646 | 14 | 1,120 | 880,770 |
| 4 | 259 | 180,181 | 15 | 1,170 | 923,891 |
| 5 | 316 | 213,063 | 16 | 1,252 | **992,441** |
| 6 | 340 | 230,219 | 17 | 1,308 | 89,315 ← auto-compact |
| 7 | 391 | 262,796 | 18 | 1,359 | 131,995 |
| 8 | 478 | 340,357 | 19 | 1,403 | 165,806 |
| 9 | 575 | 433,601 | 20 | 1,451 | 187,752 |
| 10 | 621 | 469,018 | 21 | 1,568 | 264,138 |
| 11 | 672 | 507,945 | 22 | 1,582 | 275,549 |

Ticket 16 was implemented on top of tickets 1–15 still resident in context. The same work, done
sixteenth instead of first, cost **10× more per turn**.

Every iteration also re-injected the full `/loop` skill body as a second user message — visible
as the alternating `<command-message>loop</command-message>` / skill-text pairs in the transcript.

### 1.2 Why this is expensive

Cache reads bill at 10% of base input — cheap per token, but charged on *every* token of history,
on *every* turn. On Opus 5 ($0.50/MTok cache read):

| Context | Cache-read cost per turn | Full turn (incl. ~1.5K new + 1.5K output) |
|---|---|---|
| 50K | $0.025 | $0.072 |
| 200K | $0.100 | $0.147 |
| 500K | $0.250 | $0.297 |
| 1M | $0.500 | $0.547 |

Read-only the ratio is exactly 20×; output cost dilutes it to 7.6×. **81% of the $1,444 total was
cache reads.**

### 1.3 Two distinct leaks

**Conversation bloat** — andrew-crm, dump-debugger. Tool results are small: 767,932 chars total
(~192K tokens) across 423 Bash calls in `4c15e762`, largest single result 20,733 chars. The 1M
context is *reasoning and prose*: 1.9M output tokens over 1,583 turns, ~1,200 tokens/turn. There
is nothing to prune — the fix is to stop accumulating.

**Screenshot bloat** — sqlviewer. 119 `Read` calls averaging **65,945 chars**, totalling 7.85M
chars (~1.96M tokens). Every one is a PNG in the session scratchpad read back into context:

| Chars | File |
|---|---|
| 229,852 | `scratchpad/phase2-suggest.png` |
| 199,008 | `scratchpad/phase2-freetype2.png` |
| 195,216 | `scratchpad/bit-final.png` |
| 193,656 | `scratchpad/find-step3.png` |
| 192,488 | `scratchpad/check2.png` |

Images are ordinary content blocks in message history, so each rides the cached prefix for every
subsequent turn. A 4K screenshot is 4,784 visual tokens on the high-resolution tier (Claude 4.7+,
which includes Opus 5 and Sonnet 5) — roughly 3× the standard tier, for fidelity a UI diff does
not need.

---

## 2. The correction

**One background agent per phase is contradicted by Anthropic's own documentation.**

Claude Code's subagents page lists, under *"Use your main conversation when"*:

> "Multiple phases share significant context (planning → implementation → testing)"
> "The task needs frequent back-and-forth or iterative refinement"

The agent-teams page:

> "For sequential tasks, same-file edits, or work with many dependencies, a single session or
> subagents are more effective."

And subagents do not inherit the parent's cache:

> "Its first request doesn't read the parent's cache… Subagents use the five-minute TTL even on a
> subscription."

Published multipliers: agents ~4× a chat; multi-agent systems ~15×; Claude Code agent teams ~7× a
standard session. The 15× figure is from a **research** system, and Anthropic explicitly excludes
"most coding tasks" from the multi-agent sweet spot.

A phase-per-agent pipeline pays a cold cache start per phase, loses the shared state dependent
phases need, and hands coordination back to a main thread that must re-read everything to verify.

**What is actually wanted is the same context hygiene without the agent tax: fresh sessions with
the plan file on disk as the state carrier.** This is Anthropic's documented pattern — "once the
spec is complete, start a fresh session to execute it" — and `skills/loop/SKILL.md` route B
already does it. It is gated behind `.flow/fog`, so it almost never fires.

Subagents still earn their place, for the three jobs the docs name: verbose output never
referenced again, adversarial review, and genuinely disjoint file sets.

---

## 3. Ideas

Fourteen changes in four themes. Each carries what it is, what it takes, what it buys, and what
it costs.

### Theme A — knobs you turn once

*No workflow change. Roughly 2.5× on their own.*

#### A1. Cap the window with `/autocompact 300k`
Set a hard ceiling so context can never drift past 300K instead of riding to 998K.
- **Takes:** one command, persists to user settings; or `CLAUDE_CODE_AUTO_COMPACT_WINDOW`. Range 100K–1M.
- **Buys:** caps per-turn cache tax at ~$0.15 (Opus) instead of $0.50. On `4c15e762`: $427 → ~$260.
- **Costs:** more frequent compaction, and compaction is lossy — tokens traded for summary fidelity.

#### A2. Stop running Opus 5 as the loop default
Sonnet 5 at $2/$10 is exactly 2.5× cheaper than Opus 5 on every token category, with a native 1M window at no premium.
- **Takes:** `work` and `loop` already declare `model: sonnet` — but the *session* running them is Opus. Launch loop sessions on Sonnet.
- **Buys:** $1,444 → $577 across the six sessions, changing nothing else. A 1M Sonnet turn is cheaper than a 200K Opus turn.
- **Costs:** less headroom on genuinely ambiguous tasks. Mitigated by the stop-and-ask clause already in the loop prompt.

#### A3. Never read a screenshot back into context
119 PNGs at ~66K chars each in sqlviewer, each then riding the cached prefix for every remaining turn.
- **Takes:** a line in `skills/eyes/SKILL.md` — capture, extract the verdict in text, never re-read. Downsample to ≤1568px before viewing.
- **Buys:** ~2M tokens off that session alone.
- **Costs:** cannot re-examine a screenshot later in the same session without re-capturing it.

#### A4. Set effort once, at launch
Effort level is part of the cache key; changing it mid-session re-reads the entire conversation uncached.
- **Takes:** decide at launch; add a "don't change model or effort mid-session" line to `CONVENTIONS.md`.
- **Buys:** avoids a full uncached re-read (~$5 on Opus at 1M context, per toggle). Same rule kills the `opusplan` trap, which rebuilds the cache on every plan-mode toggle.
- **Costs:** commit up front rather than dialling in as you go.

#### A5. Filter test and build output with a hook
The largest Bash results are 20K chars of build log; only failures matter.
- **Takes:** a PostToolUse hook in the existing `hooks/hooks.json` that truncates passing test output to a summary line.
- **Buys:** turns 10K-token dumps into hundreds. Compounds — every trimmed token is one you stop re-reading forever.
- **Costs:** a truncation bug can hide a real failure. Needs a conservative filter and an opt-out.

### Theme B — change what the loop runs in

*The structural fix. This is where the 5× lives.*

#### B1. Make route B the default, not the fog-only path
`skills/loop/SKILL.md` already spawns a fresh background agent — but only when `.flow/fog` exists. Invert it.
- **Takes:** edit "Pick the runner" in that skill. The plan file and handoff already carry what a cold agent needs.
- **Buys:** every effort gets the hygiene the fog path already gets. No new machinery — the branch exists and is tested.
- **Costs:** one agent for the whole effort still grows unboundedly; it just starts clean. Fixes the floor, not the slope.

#### B2. One fresh session per *task*, plan file as the state — **biggest win**
The loop iteration boundary becomes a context boundary: read the plan, implement the first unticked box, commit, tick, exit.
- **Takes:** a runner that shells `claude -p` per iteration instead of `ScheduleWakeup` in-thread. The loop prompt is already stateless — it says "find the FIRST unchecked task".
- **Buys:** per-turn context stops compounding. On `4c15e762`: 665M cache reads → ~127M. **$427 → $87 combined with Sonnet.** Also fixes context rot, Anthropic's documented quality argument for splitting.
- **Costs:** ~20–40K re-priming per iteration (noise). Real cost: cross-task memory is lost, so anything learned in task 3 must be *written down* or it is gone by task 4. The handoff file becomes load-bearing rather than decorative.

#### B3. Promote the handoff file from optional variant to required
In `templates/loop-prompt.md` handoff updates are a variant "when running unattended overnight". If sessions become disposable it is the only continuity that exists.
- **Takes:** move the handoff clause into the base anatomy; add "decisions made and why" and "what surprised me" to `templates/handoff.md`.
- **Buys:** makes per-task sessions safe. Turns workflow memory from "whatever's in the transcript" into a reviewable artifact.
- **Costs:** a few hundred tokens of writing per iteration, and a discipline that fails silently when skipped.

#### B4. Budget guard: stop the loop when context crosses a line
A hook that refuses to start another iteration above a threshold.
- **Takes:** a PreToolUse or SessionStart hook in `hooks/hooks.json`; `scripts/session-state.sh` is already where state like this lives.
- **Buys:** a hard backstop independent of whether skill instructions were followed. Would have caught all six sessions.
- **Costs:** interrupts unattended overnight runs — the exact scenario the loop was built for. Needs auto-restart or it just stops.

#### B5. Use `/subtask` (fork) for side quests that need your context
`CONVENTIONS.md` A1 bans forking outright. That is right for reviewers and wrong for cheap side reads.
- **Takes:** narrow A1 from "never fork" to "never fork a *reviewer* or a *loop*".
- **Buys:** a fork reads the parent's cache; documented as "cheaper than a fresh subagent" for tasks needing existing context.
- **Costs:** a softer rule is easier to misapply. A1's value is that it is absolute and needs no judgment.

### Theme C — put the right model on the right job

#### C1. Opus plans in its own session; Sonnet executes in others
Split at the plan boundary as a *session* boundary, not a mode toggle inside one session.
- **Takes:** a line in `flow` and `plan`: planning is an Opus session that ends by writing the plan; `/flow:loop` starts Sonnet sessions.
- **Buys:** Opus where ambiguity lives (~$5–15, context never past 100K), Sonnet for mechanical work. Avoids `opusplan`'s per-toggle cache rebuild.
- **Costs:** the plan must be genuinely self-contained. A thin plan handed to Sonnet produces confident wrong work.

#### C2. Put `model: haiku` on the mechanical subagents
Haiku 4.5 is $1/$5 — 5× cheaper than Opus. Named explicitly for "simple subagent tasks".
- **Takes:** frontmatter on any agent whose job is fetch-and-summarize. Not `fresh-eyes` — review is judgment work.
- **Buys:** cuts the cost of the delegation you *should* be doing more of, making it easier to justify.
- **Costs:** Haiku needs a 4,096-token cacheable prefix vs Opus's 512, and misses more on nuanced summarization.

#### C3. Delegate verbose reads — the delegation actually missing
Not phases. Test-suite runs reporting only failures, log processing, "where is X" searches via the `Explore` agent.
- **Takes:** a clause in `work/SKILL.md`'s Verify step. `Explore` skips CLAUDE.md and git status by design, so it is cheap.
- **Buys:** keeps output you will never reference again out of a prefix you re-read forever. This *is* the documented subagent use case.
- **Costs:** each spawn is a cold start on a 5-min TTL. Worth it above roughly 2K tokens of returned output; below that, just run the command.

### Theme D — change the shape of the thing

#### D1. Parallel where it is actually parallel: disjoint file sets
Have `/flow:plan` annotate each phase with the files it touches, then fan out only phases with no overlap and no dependency.
- **Takes:** a `files:` field per phase in `templates/plan.md`, plus overlap detection in the runner. Merge into the integration branch `work` already maintains.
- **Buys:** real wall-clock parallelism on the one axis Anthropic endorses for coding.
- **Costs:** **more tokens, not fewer** — agent teams measure ~7×. "Two teammates editing the same file leads to overwrites." Buy for speed, never for savings.

#### D2. A token budget in the plan, checked at wrap
The plan declares an expected budget; `wrap` reads the transcript's usage records and reports actual against it.
- **Takes:** a parser like the one used here (~40 lines of Python over the JSONL), wired into `skills/wrap`.
- **Buys:** turns cost from something discovered by hitting a limit into something the workflow reports. Every future change gets measured.
- **Costs:** depends on the transcript JSONL schema, which is undocumented and can change underneath you.

#### D3. Make the plan file a real state machine
Each task carries status, the commit SHA that closed it, decisions made, and what it learned — not just `[ ]` / `[x]`.
- **Takes:** restructure `templates/plan.md`; teach `work` to write the record as part of landing a slice.
- **Buys:** the prerequisite for disposable sessions. A cold agent reading a rich plan is close to a warm agent reading a transcript, at 5% of the tokens.
- **Costs:** more ceremony per task, and a file long enough to need its own trimming. Trades a token problem for a document-design problem.

#### D4. A supervisor that watches the loop instead of running it
A small, permanently-cheap session that never implements — it dispatches per-task runs, reads their handoffs, and decides whether to continue, re-plan, or stop and ask.
- **Takes:** a real orchestrator. Its context holds only the plan and one-paragraph summaries, so it stays under ~50K forever.
- **Buys:** bounded cost *and* continuity — the thing per-task sessions give up. The Opus-lead / Sonnet-worker pattern applied to implementation.
- **Costs:** the most machinery here and the most ways to fail. Anthropic's own note: an orchestration flow waiting on subagent results can stall. Do not build until per-task sessions have proven themselves.

---

## 4. Cost savings estimate

Applied to the six measured sessions — same work, same turn counts, same output. Only the context
curve and the model change.

| Configuration | Cache reads | Total | vs today |
|---|---|---|---|
| As run — Opus 5, unbounded | 2.33B | $1,444 | — |
| + Sonnet 5, nothing else changed | 2.33B | $577 | 2.5× |
| + Split at task boundaries, stay on Opus 5 | 0.95B | $768 | 1.9× |
| **+ Both: per-task sessions on Sonnet 5** | 0.95B | **$307** | **4.7×** |

The two levers are close to independent, so they multiply. Splitting alone underperforms because
output tokens do not shrink — the same work is generated either way. The model switch is what
discounts the output half.

**Method.** Split model assumes a fresh session roughly every 100 turns with average per-turn
context capped at 150K, plus 40K re-priming per restart. Rates are Anthropic's published figures
(Opus 5 $0.50/$6.25/$25 per MTok cache-read/write/output; Sonnet 5 $0.20/$2.50/$10). Token counts
are read directly from the transcripts; the arithmetic is ours, not a figure Anthropic publishes.

**Caveats.**
- Re-priming is real and already counted.
- The bigger unmodelled risk is **rework**: a cold agent misreading a thin plan can burn more than
  it saved. This is why B2 depends on B3 landing first.
- These are equivalent-API dollars. On a subscription the payoff arrives as more work per session
  limit, not a smaller bill. (The research agent spawned during this investigation died on the
  account session limit — the symptom, in real time.)

**Verdict: worth doing.** Not because 4.7× is a large number, but because most of it comes from a
config flag and a default already implemented in `skills/loop/SKILL.md`. The expensive Theme D
ideas are optional; the payoff does not depend on them.

---

## 5. Recommendation

Ordered by saving per hour of effort, not by size of saving.

| # | Do | Effort |
|---|---|---|
| 1 | **Launch loop sessions on Sonnet 5, set `/autocompact 300k`** — cheapest thing worth doing; two settings, ~2.5×, no workflow change | 10 min |
| 2 | **Flip `/flow:loop` so fresh context is the default runner** — route B exists and is tested, just gated behind `.flow/fog` | 1 hr |
| 3 | **Make the handoff mandatory, then split per task** — in that order, or task 4 loses what task 3 learned. Where the 4.7× lands | 3 hrs |
| 4 | **Screenshot discipline in `eyes` + test-output filter hook** — only matters for UI-heavy efforts, worth ~2M tokens when it does | 1 hr |
| 5 | **Token budget reported at wrap** — a measurement, not a saving; makes every later change verifiable | 3 hrs |
| 6 | **Leave the supervisor (D4) and parallel fan-out (D1) alone** — revisit when *waiting* is the complaint, not cost | later |

**Next step:** `/flow:plan` scoped to ranks 1–4. The picked ideas become the phases.

---

## 6. Open questions

- Commit the research file, or leave it untracked like a handoff? It is a design record, which
  argues for committing. *(non-blocking)*
- Is the Sonnet 5 switch acceptable for `/flow:work` slices, or only for the loop runner? The
  skills already declare `model: sonnet`; the *session* was Opus. *(blocking for rank 1)*
- Should per-task splitting use `claude -p` headless runs or spawned background agents? This
  document assumes headless — cheaper, but with no interactive stop-and-ask path, which the loop
  prompt's safety clause depends on. *(blocking for rank 3)*

## 7. Landmines

- The `flow:researcher` agent died mid-task on the account session limit. It had finished writing
  its report, so nothing was lost, but a re-run will hit the same wall. Agent id
  `adea735503bd5607b`.
- The research file has four explicitly **UNVERIFIED** claims in its §8 — including whether Claude
  Code's tool-output pruning is literally the API's `clear_tool_uses_20250919`. Do not promote
  those to fact when planning.
- No `.gitignore` in this repo. `HANDOFF-*.md` is untracked by absence rather than by rule.
- Doc-URL drift: `docs.anthropic.com/en/docs/claude-code/*` now 404s; Claude Code docs live at
  `code.claude.com/docs/en/*`.
