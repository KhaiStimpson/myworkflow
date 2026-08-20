# Conventions

How you work, graded by evidence. This supersedes the 2026-08-08 mining pass
(`worker/.scratch/orchestrator/findings/03-conventions-proposal.md`), whose stated central
weakness was that 30 of its 32 sessions were one project. That is now fixed: `sqlviewer`,
`dump-debugger` and `worker` add three more projects and one week, so several claims that were
"probably project rules" are now testable as personal ones.

**Grades:** **Strong** = recurs across ≥3 projects or stated in your own words and never
contradicted · **Moderate** = 2 projects or repeated within one · **Contested** = evidence points
both ways.

## Interaction

**I1 — Lettered options with a recommendation attached. Strong, all projects.**
You reply with one character. ~40 bare option selections in the first corpus; `worker` adds
`a`/`b`/`c`/`.`, `hanger` is almost entirely `A`/`B`/`accept`. Never present a neutral menu and
never present a single path.

**I2 — The recommendation is frequently taken unread. Strong.**
"use your recommendation", "agree and just use all your recommendations for the rest of your
questions". **Consequence:** a weak recommendation propagates silently, so every recommendation
carries its cost line, not just its verdict.

**I3 — Batch the questions. Strong, and it is a fatigue signal, not a style preference.**
"can we do multiple of these at one im getting tired of answering" (`worker`), "OK i cant answer
any more right now so write the tdd to some temp file for later" (`hanger`). Long question
sequences must checkpoint to a file so they can be abandoned mid-way without loss.

**I4 — Plan or propose first; implement only on an explicit go. Strong, all projects.**
"Make no changes just brainstorming ideas" (`sqlviewer`), "dont implement yet" (`sqlviewer`),
"plan first use artifacts for mockups with variants for me approve" (`dump-debugger`), "Plan and
propose only first" (`andrew-crm`). This was the strongest single-project claim and it now holds
across four.

**I5 — Half-done work draws the sharpest correction. Strong.**
"you only changed the colours what about layout and mobile?", "This shouldnt just be scoped to
the settings page it should be all pages", "The goal is to complete all the issues isnt it".
Deliver the whole stated scope or say explicitly what you left out.

## Visual work

**V1 — Design goes through a throwaway HTML artifact with variants before any code. Strong,
now cross-project.** Seven `andrew-crm` sessions, plus `sqlviewer` ("the goal is an artifact at
the end with the suggestions") and `dump-debugger` ("use artifacts for mockups with variants for
me approve" → "I like A let's implement it completely"). You initiate it every time. Three
variants is the default you have confirmed explicitly.

**V2 — Mobile is a first-class axis. Strong.** Four unprompted corrections. Every variant shows
desktop and mobile, unasked.

**V3 — You review with your eyes on the running app, and you find what tests miss. Strong.**
Seven distinct front-end defects in the corpus — a broken filter, white text on white, a too-tall
button, badges misaligned, controls wrong at narrow widths — **every one of them after a green
test run.** This is real, repeated, unautomated work and no gate replaces it.

**V4 — Brownfield reuses the existing design system; the decisions record outranks the mockup.
Moderate.** "actually lets not use them just use the css etc and components as a reference",
"i work on mature projects that already have a design system along with Greenfield".

## Process

**P1 — A phased markdown plan with checkboxes, plus a matching loop prompt, is the unit of
execution. Strong, now the single most portable habit you have.**
`sqlviewer` twice, `dump-debugger`, `worker`, `andrew-crm`. You ask for them together — "create a
full plan as a markdown file in the docs folder for these changes in phases and also provide a
loop command to implement them all", "generate me a loop or goal prompt for completing this",
"Review the spec.md and give me a goal command to run to complete the full implementation".
The plan lives in `docs/`. The loop prompt is part of the deliverable, not an afterthought.

**P2 — The loop prompt has a fixed anatomy. Strong.** First unchecked task only · follow the
ground rules section · build and test · tick the box · commit naming phase and task · **stop and
ask rather than guess** · do not skip ahead. Re-pasted ~20 times near-verbatim across projects.

**P3 — Ticket branches merge `--no-ff` into a long-lived integration branch, never into `dev`.
One PR at the end. Strong (andrew-crm), untested elsewhere.**
"Merge should only be to our feature branch as well i dont want this in dev until all code is
done and i have reviewed." `dev` is the default branch, not `main`.

**P4 — Comment the merge SHA on the tracking issue; do not close it. Strong (andrew-crm).**
Closing happens at PR merge or by you.

**P5 — A durable handoff file carries state between sessions. Strong.**
`HANDOFF-<effort>.md`, read first by the next session. Kept **untracked** in practice — working
state uncommitted, decisions committed.

**P6 — Scope discipline on commits. Moderate.** "don't ship harness", "ok undo the temp ci
changes", unrelated diffs get flagged and decided, never swept in.

**P7 — Small reviewable slices are what you want; batch-at-the-end is what you do. Contested,
and this gap is the reason Orchestrator exists.**
"i dont wnat to review 2000 lines of code i want to review small horizontal testable slices" —
against ~30 tickets merged unreviewed into one integration branch. Read the batching as a
workaround for per-ticket review being unaffordable by hand, not as an endorsement of big reviews.

**P8 — Finish the job: gitignore, README with screenshots and badge, commit and push.
Moderate.** Stated as one instruction in `dump-debugger`. Treat a repo as unfinished until it
presents itself.

## Testing

**T1 — Test posture is per-project, and you set it explicitly. Strong — this is new and it
overturns the old reading.** In `andrew-crm` the Playwright integration suite is the trusted
control (287 integration vs 8 domain tests, `dotnet test` gates every merge). In `sqlviewer` and
`dump-debugger` — solo greenfield desktop apps — you said **"exclude writing tests"** and
**"Do NOT write tests"**, with `dotnet build` as the only gate. So neither "integration tests are
the seam" nor "tests always" is a personal convention. **Ask the repo, or ask once and record the
answer in the plan's ground rules.**

**T2 — Behaviour-preserving is a hard constraint on refactors, proven by the suite. Strong
(andrew-crm).** With named exceptions listed explicitly.

**T3 — Never re-scaffold or squash EF migrations. Strong.** A data-safety rule.

## Research

**R1 — Spawn research agents by name, in the background. Strong.**
"spawn of a research agent to investigate", "can you spawn another research agent to
invesitgate ARN self-assertion". You act on their reports immediately and approvingly, and two
of them materially corrected tickets you had already written.

**R2 — Primary sources, inline citations, opinion in a separate labelled section, unverifiable
claims marked UNVERIFIED rather than estimated. Strong.** Every research pass in the corpus was
steered this way and it demonstrably paid off.

**R3 — Cost-consciousness is volunteered, repeatedly. Strong.** "we need to go a free option for
the MVP", "whats teh cheapes option here?", "Sounds good but also costly on tokens any other
ideas to save on tokens". Prefer free, already-owned, and cheap-model tiers; state the cost line.

## Agents

**A1 — Agents run on fresh context, never forked. Strong — stated directly.**
"noticed subagents are forking, I don't want that in this flow", and, of a plan that followed a
long grill session, "this should spawn a background agent so it has fresh context to complete
it". So no skill in this plugin sets `context: fork` and nothing spawns `subagent_type: fork`.
The reason it holds beyond the preference: a forked reviewer inherits the reasoning that wrote
the code, and a forked loop re-reads an interview every iteration to learn what the plan file
already states. Agents derive what changed from the diff, the plan and the handoff instead —
durable state that outlives the session.

## Stack (andrew-crm-scoped — do not globalise)

**S1** Vertical slices + clean architecture, **no MediatR, no AutoMapper**. You hold the
*dislikes* firmly and the *prescriptions* loosely — "Not sure what the best practices are…
you can question them as well".
**S2** Thin adapters at the HTTP edge; no persistence types past the seam.
**S3** Server-rendered, framework-native. No SPA, no bundler, no JS in views; native ES modules.
**S4** WinUI 3 for Windows desktop work (`sqlviewer`, `dump-debugger`), chosen for the look —
"we make a very beautiful app using the latest winui features".

## Still unknown

Comment density, naming conventions and module size are addressed by **no** user turn in any
session across five projects. Anything asserted about them would be invention. Source them from a
repo's own ratified documents (`CLAUDE.md`, `CONTEXT.md`, `docs/adr/`) rather than from habit.
