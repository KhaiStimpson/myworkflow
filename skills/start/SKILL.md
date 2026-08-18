---
name: start
description: The front door for any new piece of work. Investigate the task, announce a route in three lines with a one-token veto, then run it. Use when work arrives and it is not obvious whether it needs a plan, a design pass, a single slice, or just doing.
when_to_use: At the start of any new piece of work - a feature, a bug, a refactor, a redesign, a question that turns into work. Trigger phrases include "let's build", "I want to add", "can you fix", "we need to", "help me with", and any task that arrives without a stated route.
---

A task has arrived. Your job is to route it — and to be **cheap to correct**. The whole
protection of the small routes is that the proposal is fast to veto, so a wrong route costs one
character, not an explanation.

## Investigate before you ask

Read the task. Read whatever repo guidance is already privileged (`CLAUDE.md`, `AGENTS.md`,
`CONTEXT.md`, `docs/`). Then run **at most two** targeted probes, and before each one name the
boundary it tests and the result that settles it. A probe you cannot describe that way is
curiosity, not investigation — skip it.

Questions are reserved for what the repo **structurally cannot know**: intent and appetite. At
most one question about size and one about design. Everything else you decide and announce.

## The four routes

Apply the tests in this order, because a higher answer dominates the ones below it.

1. **Is anything material still undecided?** → **Route 3 — Foggy.**
   Invoke the `mattpocock-skills:wayfinder` skill. Resolve decisions until nothing is left to
   decide, then re-enter at route 2.
2. **Does it exceed one reviewable change (~400 lines)?** → **Route 2 — Planned.**
   Invoke the `plan` skill.
3. **Does it need a fresh context window of focused work?** → **Route 1 — Slice.**
   Invoke the `work` skill.
4. Otherwise → **Route 0 — Direct.** Do it here. Write no orchestration files at all.

**Invoke means invoke — call the named skill yourself with the Skill tool and carry on inside
this conversation.** Never hand the user a `/flow:*` command to type in place of invoking it
yourself; routing them back to the keyboard is the whole failure this front door exists to
prevent.

Uncertainty biases **up**, never down. Route 0 protects itself through the veto, not through
optimism.

## The design axis, evaluated every time

Independent of size. It fires when **more than one defensible visual answer exists** — not merely
because a UI file will change. Fixing a wrong colour is not a design question; deciding what the
page should feel like is. When it fires, invoke the `design` skill **first**, whatever the route,
before invoking whichever route's skill follows.

Historically this is the most common shape of your work and the easiest one to mis-route: a UI
request that lands in route 1 produces code where three mockups were wanted.

## The announcement

Three lines, then proceed after a beat. Do not stop for confirmation — except on route 3, where
chartering a map is an expensive commitment.

```
Route 2 — Planned. Four phases, touches the parser and two views.
Design: no — the existing card layout answers this.
Probe: docs/ has no plan file for this effort, so this is new work.

Say a route number to override, `design` to toggle the design pass, or `0` to just do it.
```

State a probe finding only when a probe actually ran, and keep it to one line. If you asked a
question, its answer becomes an operative scope constraint — carry it forward, do not re-litigate
it downstream.

## Standing obligations for whatever you route to

- Every route above 0 leaves a **durable file**. A route whose only output lives in this
  conversation has produced nothing.
- Any load-bearing external fact — a vendor limit, a pricing tier, a licence term, a platform
  behaviour — goes to the `researcher` agent rather than being asserted from memory. **Spawn it
  with the Agent tool, `subagent_type: researcher`, in the background**, and carry on routing
  while it runs. Naming the agent in prose without calling it is the failure mode here.
- The test posture is a **per-repo** question, never assumed. If the repo does not answer it, ask
  once and record the answer in the plan's ground rules.
