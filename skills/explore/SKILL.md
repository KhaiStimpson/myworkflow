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

## Ask, but batch

If a question would materially change the ideas, ask — but collect every question into **one**
round rather than dripping them out. Long interrogations get abandoned, and an abandoned
brainstorm leaves nothing behind.

## The handoff

When the ideas are chosen, the next step is `plan` — the picked ideas become the phases. Say that
in one line and invoke it when the user picks. Do not start planning inside this skill, and do
not start implementing at all.
