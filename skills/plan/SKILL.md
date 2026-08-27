---
name: plan
description: Turn agreed work into a phased markdown plan with checkboxes in docs/, plus the exact loop prompt that executes it — and implement none of it. Use when work exceeds one reviewable change, or when asked for "a plan with phases", "a loop command", or "a goal prompt".
model: sonnet
effort: high
---

The plan file is the **state** of the effort; the loop prompt is the **stateless engine** that
walks it. They ship together, in one turn, so they can never drift. A plan without its loop
prompt is half a deliverable.

**Write no product code in this skill.** Not a scaffold, not a stub, not "just the interface".

## Ground the plan in the repo as it is now

Read the code before writing phases. If a plan already exists for this effort, re-read it against
the current tree and say plainly what has drifted — the base app being finished after the plan
was written is the normal case, not an exception.

## The file

`docs/<effort>-plan.md`. Read `${CLAUDE_PLUGIN_ROOT}/templates/plan.md` and use it as the
skeleton.

- **Phases** in dependency order, each with a one-line goal you could judge — and **each sized to
  five to seven tasks**, because a phase is a session. See below.
- **Tasks as checkboxes**, each one a single sitting's work with an obvious done-state. If a task
  needs two deliverables, it is two tasks.
- **Ground rules** — the section the loop prompt points at, and the reason the loop stays short.
  It carries the build command, the test posture, the branch topology, what is out of scope, and
  any decision already made that must not be re-litigated.
- **Open questions** at the bottom, if any. A task that depends on one is not ready to be ticked
  into the loop.

**The test posture goes in Ground rules, decided once.** There is no global default — read the
repo; if it does not answer, **ask once**, and record the answer so the loop never re-asks.

**Wrap the build and test commands in `scripts/run-gated.sh`.** It keeps the full log on disk and
puts a pass line in context instead of a thousand lines of green output. Failures still show real
failing lines — the filter never summarises a red run into uselessness.

## Size the phases, because a phase is a session

A phase now decides how long a session lives: `/flow:loop` ends the session when the last task in a
phase is ticked and continues the next phase on fresh context. So phase size is no longer a matter
of taste.

**Target five to seven tasks per phase.** That number is measured, not guessed. In the corpus, a
loop iteration costs $3–8 while context is under ~260K and $17–124 above it, and five to seven
tasks is what fits below that knee. The evidence is in `docs/spec-session-economics.md`.

- **Where dependency order and sizing conflict, dependency wins.** Split the oversized phase at its
  least-coupled seam into `Phase 3a` / `Phase 3b` rather than reordering work that cannot move.
- **A phase you cannot get under the ceiling is a finding, not a failure.** Say so in the plan when
  you write it, so it is known before it costs anything rather than discovered mid-loop.
- **Do not pad.** A genuinely three-task phase stays three tasks; inventing filler to hit a number
  is worse than a short session.

Say how many sessions the effort will take when you present the plan. That number is the point:
the cost is knowable before the work starts.

## Record the effort, so the rest of the flow can find it

Write the effort slug to `.flow/current` (create the directory if needed). `/flow:loop` and the
session hooks read it; without it they have to guess which effort is live.

If a fog session preceded this plan, leave `.flow/fog` alone — `/flow:loop` reads it to decide
whether to run the loop here or hand it to a fresh agent. Do not write it yourself; `start` owns
it.

## The loop prompt

The anatomy is fixed and lives in exactly one place. Read
`${CLAUDE_PLUGIN_ROOT}/templates/loop-prompt.md`, fill it in with the real file path and the real
build and test commands, and emit it in a fenced block at the end. **Do not reconstruct it from
memory** — a paraphrase is how the plan and its engine drift apart.

Then say, in one line, that **`/flow:loop`** starts it — it fills this same template in from the
plan and hands it to `/loop`, so nobody has to paste anything. `/goal` remains available for
driving to completion in one attended session.

## Stop here

Present the phase list and the loop prompt, and stop. Implementation starts on an explicit go —
and it starts in `work`, not here.

Why the plan and the prompt ship together, and why test posture is per-repo: `reference.md`.
