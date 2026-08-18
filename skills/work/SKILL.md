---
name: work
description: Implement exactly one slice — one task or one ticket — on its own branch, verify it, capture screenshots if it touches UI, and land it on the integration branch. Use as the body of a loop iteration, or for a single self-contained change.
model: sonnet
effort: medium
allowed-tools: Bash(git status *), Bash(git diff *), Bash(git log *), Bash(git add *), Bash(git checkout *), Bash(git switch *), Bash(git branch *)
---

One slice. One branch. One reviewable diff. The discipline is **refusing to do the next thing**
while you are in this one.

## Before touching code

1. Read the ground rules of whatever sent you here — the plan file, the ticket, the pack. They
   carry the build command, the test posture and the out-of-scope list, and they outrank your
   instincts about all three.
2. Cut the ticket branch from the integration branch:

```
integration/<effort>                    cut from dev, long-lived, one per effort
  └── integration/<effort>/<n>-<slug>    one per task, cut from the integration branch
```

`dev` is the default branch, not `main`. Nothing reaches `dev` until the whole effort is reviewed.

3. **If the task is ambiguous, blocked, or needs a decision that is not yours — stop and ask.**
   Do not guess. This is what makes unattended running safe.

## Implement

- **Only this task's scope.** An unrelated diff that appears — a stray project file, a tempting
  cleanup, a carry-forward — gets **flagged and decided**, never swept into the commit.
- **Behaviour-preserving means behaviour-preserving.** On a refactor, appearance and behaviour
  change only where an exception is named explicitly.
- **Never re-scaffold or squash migrations.**
- Match the code around you — its naming, comment density and idioms — rather than importing a
  house style from elsewhere.
- If the diff drifts past ~400 lines, say so and propose the split. Land it whole if it must land
  whole, but state the number.

## Verify

1. Run the build.
2. Run the test suite **if the ground rules say there is one**. Do not invent a test posture the
   effort decided against, or skip one it decided for.
3. **If this slice touches UI, invoke `eyes` before committing.** A green run is not done for
   anything a person can see: every front-end defect in the mined corpus passed a green test run
   first.

## Land it

1. Commit, naming the phase and the task.
2. Tick the checkbox in the plan file, in the same commit or the one right after.
3. Spawn the Agent tool with `subagent_type: fresh-eyes` on this slice's diff. Act on what it
   returns before merging. If it finds nothing, say so and carry on.
4. Merge `--no-ff` into the integration branch and delete the ticket branch.
5. If a tracker issue exists: **comment** the merge SHA on it. **Do not close it.**
6. Report in three lines: what landed, what you verified it with, and what you flagged rather
   than fixed.

Then stop. The next task is the next iteration's problem.

Why the topology and the stop-rule are shaped this way: `reference.md`.
