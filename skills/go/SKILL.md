---
name: go
description: Advance the live effort by one task — read the plan, implement the first unchecked item, verify it, land it. Use to continue work already planned, instead of pasting the loop prompt by hand.
model: sonnet
effort: medium
---

## Where the effort stands

- Effort: !`cat .flow/current 2>/dev/null || echo none`
- Branch: !`git branch --show-current 2>/dev/null || echo "(not a git repo)"`
- Working tree: !`git status --porcelain 2>/dev/null | head -20 || echo clean`
- Plan files: !`ls docs/*-plan.md 2>/dev/null || echo none`
- Next task: !`grep -h -m1 -- '- \[ \]' docs/*-plan.md 2>/dev/null || echo "none - all checked"`
- Handoff: !`ls HANDOFF-*.md 2>/dev/null || echo none`

## Decide what to do with that

**No effort and no plan file** → there is nothing to advance. Say so and offer `/flow` instead.
Do not invent an effort.

**Next task is "none - all checked"** → the plan is complete. Say so and invoke `wrap` for
ending B. Do not look for more work.

**A handoff file exists** → read it first. It carries what must not be re-litigated and what was
deliberately left, and re-deciding a settled question is the expensive failure here.

**Otherwise** → advance exactly one task:

1. Read the plan file's **Ground rules** section and the phase description for that task. They
   carry the build command, test posture, branch topology and out-of-scope list.
2. **Invoke the `work` skill** on that one task. It handles the branch, the implementation, the
   verification, `eyes` if the slice touches UI, the `fresh-eyes` read, and the merge.
3. Tick the checkbox and report in three lines.

Then **stop**. One task per invocation. Say `go` again for the next one, or hand it to `/loop
/flow:go` to run unattended.

## The rules that make this safe to repeat

- **One task per invocation.** Do not skip ahead, and do not batch two because they look related.
- **If the task is ambiguous, blocked, or needs a decision that is not yours — stop and ask.**
  Guessing produces work that has to be unpicked, which costs more than the interruption.
- **If the plan has gone stale against the tree** — the base app finished after the plan was
  written, tasks describing code that no longer exists — say so and re-run `plan` against the
  current repo rather than reconciling it task by task.
