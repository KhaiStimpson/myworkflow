---
name: plan
description: Turn agreed work into a phased markdown plan with checkboxes in docs/, plus the exact loop prompt that executes it — and implement none of it. Use when work exceeds one reviewable change, or when asked for "a plan with phases", "a loop command", or "a goal prompt".
---

The plan file is the **state** of the effort; the loop prompt is the **stateless engine** that
walks it. They ship together, in one turn, so they can never drift. A plan without its loop prompt
is half a deliverable.

**Write no product code in this skill.** Not a scaffold, not a stub, not "just the interface".

## Ground the plan in the repo as it is now

Read the code before writing phases. If a plan already exists for this effort, re-read it against
the current tree and say plainly what has drifted — the base app being finished after the plan was
written is the normal case, not an exception.

## The file

`docs/<effort>-plan.md`. Read `${CLAUDE_PLUGIN_ROOT}/templates/plan.md` and use it as the
skeleton.

- **Phases** in dependency order, each with a one-line goal you could judge.
- **Tasks as checkboxes**, each one a single sitting's work with an obvious done-state. If a task
  needs two deliverables, it is two tasks.
- **Ground rules** — the section the loop prompt points at, and the reason the loop stays short.
  It carries the build command, the test posture, the branch topology, what is out of scope, and
  any decision already made that must not be re-litigated.
- **Open questions** at the bottom, if any. A task that depends on one is not ready to be ticked
  into the loop.

### The test posture goes in Ground rules, decided once

There is no global default. On a shared codebase with a real suite, that suite gates every task.
On a solo greenfield app, "do not write tests, `build` is the gate" is a legitimate and previously
chosen answer. Read the repo; if it does not answer, **ask once** — and record the answer in
Ground rules so the loop never re-asks.

## The loop prompt

The anatomy is fixed and it lives in exactly one place. Read
`${CLAUDE_PLUGIN_ROOT}/templates/loop-prompt.md`, fill the template in with the real file path
and the real build and test commands, and emit it in a fenced block at the end ready to paste
after `/loop` or `/goal`. **Do not reconstruct the prompt from memory** — the template is
canonical, and a paraphrase is how the plan and its engine drift apart.

Say which to use: **`/loop`** for unattended repetition, **`/goal`** to drive to completion in
one attended session.

## Stop here

Present the phase list and the loop prompt, and stop. Implementation starts on an explicit go —
and it starts in `/flow:work`, not here.
