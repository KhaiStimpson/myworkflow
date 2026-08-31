---
name: explore
description: Brainstorm an open-ended idea without touching a single file, and land it as an artifact of concrete options with a recommendation. Use when the request is "brainstorm", "come up with N suggestions", "be creative", "what could we do here" — anything where the answer is ideas, not code.
model: sonnet
effort: high
---

The request is for **ideas**, and the correct number of files changed is zero. Say so once at the
top and mean it — a brainstorm that quietly edits something has failed at the only rule it had.

## Read enough to be specific, without paying for it

Generic ideas are worthless here: ground every suggestion in something you actually saw — this
parser, this view, this table. A suggestion that could have been written without opening the repo
does not belong in the list.

But do the reading **in a subagent**. Spawn the Agent tool with `subagent_type: Explore` and ask
for the map you need — the surfaces in play, what each does, where the seams are — and build on
what it returns. Reading twenty files into this conversation to produce ten bullet points is the
expensive way to get the same list.

## Shape of the output

An **artifact** — a self-contained HTML page, published so it can be read on a phone. Not a wall
of chat text.

- **Cover the range before you narrow it.** Cheap-and-obvious through expensive-and-ambitious,
  including at least one idea that changes the shape of the product rather than decorating it.
  An LLM-in-the-loop option counts as fair game, not as a cop-out.
- **Each idea gets:** what it is in one line, what it would take, what it buys, and what it
  costs. The cost line is not optional — it is frequently the only thing read before a
  recommendation is accepted.
- **Group into a small number of themes** so the whole thing is skimmable, with depth underneath.
- **End with a recommendation**: a shortlist, in order, with the reason for the ordering and the
  cheapest thing worth doing first.
- **Red-team it before publishing.** Spawn one fresh subagent — not a fork — with the draft
  shortlist and its reasoning, and ask where it is thin: which cost line is optimistic, which
  idea is framed to win, what a skeptical reader would push on. Fold what survives into a short
  **Pressure-tested** note on the artifact. The pass costs the reader nothing and catches what a
  batched question round cannot.

## Ask, but batch

If a question would materially change the ideas, ask — but collect every question into **one**
round rather than dripping them out. Long interrogations get abandoned, and an abandoned
brainstorm leaves nothing behind.

## Grill the pick before it becomes a plan

Once the artifact is published and the user leans toward a shortlist, that shortlist is about to
turn into `plan` phases — so grill it first. Invoke `${user_config.fog_skill}` on the chosen
direction, bounded: a few questions on that one target, not a walk down every branch, and stop
when the direction holds up or the user tires. **Invoke means invoke** — call the skill yourself
with the Skill tool; never hand the user a `/flow:*` command to type instead.

Log each resolved question and its answer to `.flow/explore-grill` as you go, creating the
directory if needed. That keeps the round abandonable without loss, and `plan` reads the file so
the grilling is not repeated.

## The handoff

When the pick has been grilled and holds, the next step is `plan` — the chosen ideas become the
phases, and the `.flow/explore-grill` notes carry across with them. Say that in one line and
invoke `plan`. Do not start planning inside this skill, and do not start implementing at all.
