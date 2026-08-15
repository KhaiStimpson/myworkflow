---
name: work
description: Implement exactly one slice — one task or one ticket — on its own branch, verify it, capture screenshots if it touches UI, and land it on the integration branch. Use as the body of a loop iteration, or for a single self-contained change.
disable-model-invocation: true
---

One slice. One branch. One reviewable diff. The discipline here is not thoroughness — it is
**refusing to do the next thing** while you are in this one.

## Before touching code

Read the ground rules of whatever sent you here (the plan file, the ticket, the pack). They carry
the build command, the test posture, and the out-of-scope list, and they outrank your instincts
about all three.

Branch topology, unless the ground rules say otherwise:

```
integration/<effort>          cut from dev, long-lived, one per effort
  └── integration/<effort>/<n>-<slug>   one per task, cut from the integration branch
```

`dev` is the default branch, not `main`. Ticket branches merge back with `--no-ff` and a
`Merge #<n>: <title>` message. **Nothing reaches `dev` until the whole effort is reviewed.**

## Stop rather than guess

If the task is ambiguous, blocked, or needs a decision that is not yours — **stop and ask.** This
is the single most repeated instruction in every loop prompt in the corpus, and it is what makes
unattended running safe. Guessing produces work that has to be unpicked, which costs more than the
interruption ever would.

## Implement

- **Only this task's scope.** An unrelated diff that appears — a stray project file, a tempting
  cleanup, a carry-forward from another concern — gets **flagged and decided**, never swept into
  the commit. Silently broadening the blast radius is the correction issued most often.
- **Behaviour-preserving means behaviour-preserving.** On a refactor, appearance and behaviour
  change only where an exception is named explicitly.
- **Never re-scaffold or squash migrations.**
- Match the code around you — its naming, its comment density, its idioms — rather than importing
  a house style from elsewhere.

## Verify

Run the build. Run the test suite **if the ground rules say there is one** — do not invent a test
posture the effort has already decided against, and do not skip one it has decided for.

**A green run is not done for anything a person can see.** If this slice touches UI, run
`/flow:eyes` before committing: desktop and mobile screenshots into `docs/screenshots/<slug>/`,
and eyes actually on the running app. Every front-end defect in the mined corpus passed a green
test run first.

If the diff is drifting past ~400 lines, say so and propose the split. Land the work if it must
land whole — but the number gets stated, because a slicing error that stays invisible repeats.

## Land it

1. Commit, naming the phase and the task.
2. Tick the checkbox in the plan file, in the same commit or the one right after.
3. Merge `--no-ff` into the integration branch and delete the ticket branch.
4. If a tracker issue exists: **comment** the merge SHA on it. **Do not close it** — closing is
   the human's call, or happens at PR merge.
5. Report in three lines: what landed, what you verified it with, and anything you flagged
   rather than fixed.

Then stop. The next task is the next iteration's problem.
