---
name: eyes
description: Run the app, look at it at desktop and mobile widths, and capture durable screenshots — the review pass that green tests do not perform. Use before committing any UI-touching change, and before asking for approval on visual work.
disable-model-invocation: true
---

Every front-end defect in the mined corpus was found by a human looking at the running app,
**after** a green test run: a filter that showed everything, white text on white, a merge button
too tall, a badge misaligned, controls that shrank wrong at narrow widths. The suite asserts
behaviour; nobody was asserting appearance. That is this skill's entire job.

## Get it running

Use the project's own launch path — `.claude/launch.json` via `preview_start` if it exists, the
documented dev command otherwise. If the app will not start, that **is** the finding: report it
with the actual error and stop. A missing screenshot is a failure, not a skipped step.

## Capture both breakpoints

- **Desktop 1280×800** and **mobile 390×844**, every time.
- Into `docs/screenshots/<slug>/`, committed with the slice — durable, so a reviewer weeks later
  sees what you saw.
- Capture the states this change actually reaches: not just the happy view, but empty, long
  content, and error where they exist on the path you touched.

For a headless capture in an unattended session, Playwright's bundled `chrome-headless-shell`
invoked directly is the path that works, and it needs permissions that allow it to run without
prompting. Write a receipt beside the images saying what was captured or why it could not be — a
structurally distinct "could-not-capture" beats a silent absence.

## Look, with this checklist

Judge against these, because these are the classes that have actually escaped:

1. **Contrast** — is any text invisible against its background, in either theme?
2. **Narrow widths** — do controls shrink, wrap, or overlap wrongly between the breakpoints?
3. **Vertical rhythm** — is anything conspicuously too tall, too tight, or misaligned with its
   neighbours?
4. **Data density** — does it still hold with long strings, many rows, and zero rows?
5. **Regression** — is anything now showing that should be filtered, or missing that should show?
6. **Reuse** — does this look like the rest of the app, or like it was designed separately?

## Report

Screenshots first, then a short list of what you found, then what you are **not** sure about.
Annotate freely — but a model's read of a screenshot informs and never blocks. **The human is the
arbiter of appearance**, and this pass exists to put the right image in front of them, not to
approve on their behalf.
