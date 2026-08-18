# Why the plan works this way

Background for `plan`. Not loaded unless something here is in question.

## Why the plan and the loop prompt ship together

They are two halves of one machine. The plan file is the **state**; the loop prompt is a
**stateless engine** that walks it. Because the state lives on disk and not in a conversation, a
crashed session costs nothing — the next iteration reads the file and continues.

This pairing is the single most portable habit in the corpus: "create a full plan as a markdown
file in the docs folder for these changes in phases and also provide a loop command to implement
them all", "generate me a loop or goal prompt for completing this". Asked for together, every
time. Shipping one without the other produces something that cannot be run.

## Why the prompt points at Ground rules instead of restating them

It keeps the prompt short enough to paste and re-paste, and it puts every binding constraint in
one editable place. Change the build command once in the plan and every future iteration picks it
up; bake it into the prompt and you have two sources of truth and a silent drift.

## Why test posture is per-repo and never assumed

This overturns an earlier reading. In `andrew-crm` the Playwright integration suite is the trusted
control — 287 integration tests against 8 domain tests, `dotnet test` gating every merge. In
`sqlviewer` and `dump-debugger`, both solo greenfield desktop apps, the instruction was explicit:
"exclude writing tests", "Do NOT write tests", with `dotnet build` as the only gate.

So neither "integration tests are the seam" nor "tests always" is a personal convention. Ask the
repo, or ask once and record the answer — and never re-ask mid-loop, because a loop that
re-opens a settled question is a loop that stops.

## Why no code here, not even a scaffold

"Make no changes just brainstorming ideas", "dont implement yet", "Plan and propose only first."
Held across four projects. A scaffold written during planning is code nobody approved, and it
biases every phase that follows toward the shape it happened to take.
