# The workflow

This is the shape your work already has, written down. Nothing here is invented — every stage
below appears in your sessions across `andrew-crm`, `sqlviewer`, `dump-debugger`, `hanger` and
`worker`. See [CONVENTIONS.md](CONVENTIONS.md) for the evidence behind each rule.

## The spine

```
        ┌─────────┐
        │ /flow:start │  route it — announce, don't interview
        └────┬────┘
             │
   ┌─────────┼──────────────┬────────────────┐
   │         │              │                │
 Direct   Slice          Planned           Foggy
 (0)      (1)            (2)               (3)
   │         │              │                │
   │    /flow:work    /flow:plan → loop   fog skill → /flow:plan
   │         │              │                │
   └─────────┴──────┬───────┴────────────────┘
                    │
          ┌─────────▼─────────┐
          │  /flow:eyes       │  run it, look at it, desktop + mobile
          └─────────┬─────────┘
                    │
          ┌─────────▼─────────┐
          │  /flow:wrap       │  handoff · integration PR · README
          └───────────────────┘
```

Two things ride **alongside** any route, not inside it:

- **Design** — if more than one defensible visual answer exists, `/flow:design` runs first and
  produces an HTML artifact with three variants before a line of product code is written.
- **Fog** — route 3 hands off to a configured skill, by default
  [`grill-me`](https://github.com/mattpocock/skills) from Matt Pocock's skills (MIT), which
  interviews a plan until every branch resolves. Swap it for `wayfinder` in the plugin's settings
  when the work is large enough to want decision tickets on a tracker.
- **Research** — any load-bearing external fact goes to the `researcher` agent in the
  background, which writes a cited file to `docs/research/` and never blocks the current turn.

## The four routes

| Route | Test | What happens | Your artifact |
|---|---|---|---|
| **0 Direct** | Fits in this session, one obvious answer | Just do it. No files, no ceremony. | the diff |
| **1 Slice** | Needs a fresh window, fits one reviewable change | `/flow:work` on one branch | one branch + screenshots |
| **2 Planned** | More than one reviewable change | `/flow:plan` writes a phased checkbox plan **and the `/loop` prompt that executes it** | `docs/<effort>-plan.md` |
| **3 Foggy** | Something material is still undecided | The configured fog skill until the fog clears, then route 2 | decision records |

Uncertain routing biases **up**, never down. A route is *announced* in three lines with a
one-token veto — it is not a questionnaire. Route 3 is the only one that stops for confirmation,
because chartering a map is expensive.

## The loop is the engine

Route 2 is what you actually do most, and its heart is a prompt you have hand-written and
re-pasted ~20 times verbatim. `/flow:plan` now generates it with the plan, so the plan and the
prompt that executes it can never drift:

Its anatomy lives in exactly one place — [`templates/loop-prompt.md`](templates/loop-prompt.md)
— and `/flow:plan` fills that template in rather than paraphrasing it, so the plan, the prompt
and the documentation cannot drift apart.

Run it with `/loop` (unattended, repeats) or `/goal` (drives to completion). The plan file is the
state; the loop is stateless. That is why a crashed session costs nothing.

## Where the human belongs

You review with your eyes, on the running app — and in the mined corpus **every single front-end
defect you caught had already passed a green test run**. So the system never claims a UI change
is done on green tests alone. `/flow:eyes` is a required stage for any UI-touching work, and it
produces durable desktop **and** mobile screenshots, because mobile is the axis you have had to
ask for four separate times.

## How this relates to Orchestrator

Orchestrator (a separate, private repo) specifies the
automated version of this same routing model — conductors, spawned sessions, context packs,
status files. The routes here are deliberately the same four so that nothing you learn now is
thrown away. The difference is who drives: **here, you do.** This is the hand-driven system you
can use today while Orchestrator gets built, and it is the behavioural spec Orchestrator has to
reproduce.
