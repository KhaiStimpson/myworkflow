---
name: flow
description: Front door for any new piece of work — routes it, then runs the route end to end. Use when you want the whole working loop rather than one stage of it.
argument-hint: [what you want to build or fix]
model: sonnet
effort: low
---

The user's task: **$ARGUMENTS**

This is a macro. It runs the whole loop so no one has to remember which stage comes next.

## Run the route, do not narrate it

1. **Invoke the `start` skill** with the task above. It investigates, picks a route, and
   announces it in three lines with a one-token veto.
2. **Honour the veto.** If the user answers with a route number, `design`, or `0` before you
   proceed, that overrides the announced route. Anything else means carry on.
3. **Run the route to its end**, invoking each skill yourself with the Skill tool:

   | Route | What you invoke, in order |
   |---|---|
   | 0 Direct | Nothing. Do the work here, then stop. |
   | 1 Slice | `work` → `wrap` |
   | 2 Planned | `plan`, then stop and present the phases. |
   | 3 Foggy | `${user_config.fog_skill}`, then re-enter at route 2. |

   If the design axis fired, `design` runs **first**, whatever the route.

4. **Route 2 stops at the plan.** Implementation starts on an explicit go, and it starts in
   `loop` — never inside this macro. Presenting a plan and then building it unasked is the one way
   this macro can do real damage.

5. **On the go, invoke `loop`.** It fills in the loop prompt from the plan and starts the engine.
   If route 3 fired on the way here, `loop` will hand execution to a fresh background agent rather
   than loop on top of the interview — that is deliberate, and this macro does not override it.

## Never hand back a command

Every stage here is a skill you invoke, not a command the user types. The only things they should
ever need to type are `/flow` and `/flow:loop`.

And every agent any of these stages spawns starts on **fresh context** — never `subagent_type:
fork`, never `context: fork` in frontmatter.

## When the loop is already running

If `.flow/current` exists and names a live effort, this is probably not new work — say so in one
line and invoke `loop` instead of starting a second effort alongside the first.
