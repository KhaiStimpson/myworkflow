---
name: eyes
description: Run the app, look at it at desktop and mobile widths, and capture durable screenshots — the review pass that green tests do not perform. Use before committing any UI-touching change, and before asking for approval on visual work.
model: sonnet
effort: medium
context: fork
agent: general-purpose
background: false
paths: ["**/*.tsx", "**/*.jsx", "**/*.vue", "**/*.svelte", "**/*.razor", "**/*.cshtml", "**/*.xaml", "**/*.css", "**/*.scss", "**/*.html"]
allowed-tools: Read, Glob, Grep, Bash(npx playwright *), Bash(*chrome-headless-shell*), Bash(mkdir *), Bash(npm run *), Bash(pnpm *), Bash(yarn *), Bash(dotnet run *)
---

Run the app and look at it. Every front-end defect in the mined corpus was found by a human
looking at the running app **after** a green test run. The suite asserts behaviour; nobody was
asserting appearance.

You are running in a forked context. You have the repo and the running app, not the
conversation — derive what changed from the git diff and the working tree.

## Procedure

1. **Launch.** Use `.claude/launch.json` via `preview_start` if it exists, otherwise the
   documented dev command. If the app will not start, that **is** the finding: report it with
   the actual error and stop. A missing screenshot is a failure, not a skipped step.
2. **Identify the slug** — the branch name's task slug, or the plan's last ticked task.
3. **Capture desktop 1280×800 and mobile 390×844**, every time, into
   `docs/screenshots/<slug>/`. For headless capture, Playwright's bundled
   `chrome-headless-shell` invoked directly is the path that works.
4. **Capture the states this change actually reaches** — not just the happy view, but empty,
   long content, and error where they exist on the path you touched.
5. **Write a receipt** beside the images saying what was captured, or why it could not be. A
   structurally distinct "could-not-capture" beats a silent absence.
6. **Judge against the checklist below**, then report.

## The checklist

These are the classes that have actually escaped, so judge against these:

1. **Contrast** — is any text invisible against its background, in either theme?
2. **Narrow widths** — do controls shrink, wrap, or overlap wrongly between the breakpoints?
3. **Vertical rhythm** — is anything conspicuously too tall, too tight, or misaligned?
4. **Data density** — does it hold with long strings, many rows, and zero rows?
5. **Regression** — is anything now showing that should be filtered, or missing that should show?
6. **Reuse** — does this look like the rest of the app, or like it was designed separately?

## Report

Return: the screenshot paths, then what you found, then what you are **not** sure about. Do not
return the images themselves — the paths are the deliverable, and the human opens them.

Annotate freely, but **a model's read of a screenshot informs and never blocks**. The human is
the arbiter of appearance. This pass exists to put the right image in front of them, not to
approve on their behalf.
