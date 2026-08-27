# <Effort> — plan

Status: not started · Branch: `integration/<effort>` · Written: <date>

## Goal

<What "done" looks like, in two or three lines. Judgeable, not aspirational.>

## Ground rules

The loop prompt points here, which is why the loop prompt stays short. Everything binding lives in
this section.

- **Build:** `scripts/run-gated.sh <exact command>`
- **Tests:** `scripts/run-gated.sh <exact command>` — or **do not write tests; the build is the
  gate.** Decided once, recorded here, never re-asked mid-loop.
- **Model:** `sonnet` for loop iterations unless this effort needs otherwise. Recorded so the cost
  posture is a decision, not whatever was selected that day.
- **Context backstop:** `250000` — the safety net, not the trigger. Phases end sessions; this
  catches a runaway task. A session that trips it means a phase was sized wrong.
- **Branching:** ticket branches off `integration/<effort>`, merged back `--no-ff`. Nothing
  reaches `dev` until the whole effort is reviewed.
- **UI changes:** desktop (1280×800) and mobile (390×844) screenshots into
  `docs/screenshots/<slug>/` before the commit. A green build is not done for anything visible.
- **Out of scope:** <the things that will tempt an implementer and must not be swept in>
- **Already decided, do not re-litigate:** <decisions with a one-line reason each>
- One task per iteration. Stop and ask rather than guess. Do not skip ahead.

## Phase 1 — <name>

<One line: what this phase achieves and why it comes first.>

**A phase is a session.** Five to seven tasks — enough to be worth a fresh context, few enough to
stay under the cost knee. Split an oversized phase into `1a` / `1b` at its least-coupled seam
rather than letting it run long.

- [ ] <Task — one sitting, one deliverable, obvious done-state>
- [ ] <Task>
- [ ] <Task>
- [ ] <Task>
- [ ] <Task>
- [ ] <Task>

## Phase 2 — <name>

<One line.>

- [ ] <Task>
- [ ] <Task>
- [ ] <Task>
- [ ] <Task>
- [ ] <Task>

## Open questions

<Anything unresolved. A task that depends on one of these is not ready to be ticked into the loop
— mark it, or move it to a later phase.>

- [ ] <Question — blocking / non-blocking>
