---
name: wrap
description: Close out a session or an effort — write the handoff file, open the integration PR, comment the tracker, and make the repo present itself. Use when stopping mid-effort, when a loop finishes, or when the work is done.
model: sonnet
effort: low
---

Two different endings. Read which one you are at before writing anything.

## Ending A — the session stops, the effort continues

Write or update `HANDOFF-<effort>.md` at the repo root, **untracked**. Working state stays out of
git; decisions go in the plan and the design record, which are committed.

Read `${CLAUDE_PLUGIN_ROOT}/templates/handoff.md` and use it as the skeleton. A hook may already
have written the mechanical spine — branch, SHA, phase, next task, dirty files. **Your job is the
half a hook cannot write:**

- **Do not re-litigate** — decisions already made, one line each with the reason.
- **Landmines** — what broke, what was flaky, what looked wrong and was deliberately left.
- **Open questions**, each marked blocking or not.

The bar: a session that reads only this file and the plan can carry on without the transcript.
If it cannot, the handoff is not finished.

## Ending B — the effort is done

1. **Verify the whole integration branch**, not just the last slice. Full build, full suite if
   there is one, and invoke `eyes` across the UI surfaces the effort touched.
2. **Open one PR** from `integration/<effort>` into `dev` — one for the effort, not one per task.
   The body walks the slices in dependency order, one line each with its merge SHA, so the
   reviewer can walk them individually instead of reading one unreadable diff.
3. **Comment the merge SHAs** on the tracker issues. **Do not close them.**
4. **Flag what was deferred** — everything flagged rather than fixed during the effort, in one
   list, so it becomes follow-up tickets rather than forgotten context.
5. **Make the repo present itself**: a real `.gitignore`, and a `README.md` about the app — what
   it does, screenshots from `docs/screenshots/`, and any badge the project uses. A repo without
   this is not finished, it is just merged.
6. **Delete the handoff file**, and clear the effort markers — `.flow/current` and `.flow/fog`.
   Their state now lives in the PR, and a stale marker sends the next `/flow:loop` at an effort
   that is already finished.

## Either way

Say in one line what you did **not** do. Silent omissions are the most expensive thing this
workflow can produce, and this is the last place to catch one.
