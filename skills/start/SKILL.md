---
name: start
description: The front door for any new piece of work. Investigate the task, announce a route in three lines with a one-token veto, then run it. Use when work arrives and it is not obvious whether it needs a plan, a design pass, a single slice, or just doing.
when_to_use: At the start of any new piece of work - a feature, a bug, a refactor, a redesign, a question that turns into work. Trigger phrases include "let's build", "I want to add", "can you fix", "we need to", "help me with", and any task that arrives without a stated route.
model: sonnet
effort: low
---

Route the work, and be **cheap to correct**. A wrong route must cost one character, not an
explanation.

## What the repo already says

- Branch: !`git branch --show-current 2>/dev/null || echo "(not a git repo)"`
- Plan files: !`ls docs/*-plan.md 2>/dev/null || echo none`
- First unchecked task: !`grep -h -m1 -- '- \[ \]' docs/*-plan.md 2>/dev/null || echo none`
- Privileged guidance: !`ls CLAUDE.md AGENTS.md CONTEXT.md 2>/dev/null || echo none`
- Handoff: !`ls HANDOFF-*.md 2>/dev/null || echo none`

Read whatever that found before deciding anything, then run **at most two** further probes,
naming the boundary each tests before you run it. Questions are reserved for what the repo
structurally cannot know — intent and appetite: at most one about size, one about design.

## Route it

Apply in order. A higher answer dominates the ones below it.

1. **Anything material still undecided?** → **Route 3 — Foggy.** Invoke the
   `${user_config.fog_skill}` skill, resolve until nothing is left to decide, then re-enter at
   route 2. Route 3 is the only route that stops for confirmation first. **Record that it ran** —
   write the skill name and the date to `.flow/fog`, creating the directory if needed. That one
   line is how `/flow:loop` knows this conversation is carrying an interview and hands execution
   to a fresh agent instead of looping on top of it.
2. **More than one reviewable change (~400 lines)?** → **Route 2 — Planned.** Invoke `plan`.
3. **Needs a fresh context window of focused work?** → **Route 1 — Slice.** Invoke `work`.
4. Otherwise → **Route 0 — Direct.** Do it here. Write no orchestration files at all.

**Invoke means invoke** — call the named skill yourself with the Skill tool and carry on in this
conversation. Never hand the user a `/flow:*` command to type in place of invoking it. And
uncertainty biases **up**, never down.

## The design axis, evaluated every time

Independent of size. It fires when **more than one defensible visual answer exists** — not merely
because a UI file changes. Fixing a wrong colour is not a design question; deciding what the page
should feel like is. When it fires, invoke `design` **first**, whatever the route.

## Announce, then proceed

Three lines, then go — no confirmation except on route 3.

```
Route 2 — Planned. Four phases, touches the parser and two views.
Design: no — the existing card layout answers this.
Probe: docs/ has no plan file for this effort, so this is new work.

Say a route number to override, `design` to toggle the design pass, or `0` to just do it.
```

State a probe finding only when a probe actually ran. An answer you asked for becomes a binding
scope constraint — carry it forward, do not re-litigate it downstream.

## Standing obligations

- Every route above 0 leaves a **durable file**. A route whose only output is this conversation
  has produced nothing.
- Load-bearing external facts — vendor limits, pricing, licence terms, platform behaviour — go
  to the `researcher` agent: **spawn it with the Agent tool, `subagent_type: researcher`, in the
  background** and carry on routing. Naming the agent without calling it is the failure here.
- **Every agent this flow spawns starts on fresh context.** Never `subagent_type: fork`, never
  `context: fork` in a skill's frontmatter — a forked agent inherits this conversation and returns
  its assumptions back to it.
- Test posture is **per-repo**, never assumed. If the repo does not answer it, ask once and
  record the answer in the plan's ground rules.

Why these routes and not others: `reference.md`.
