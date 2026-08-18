# myworkflow

Your working loop, packaged as a Claude Code plugin — derived from ~40 of your sessions across
`andrew-crm`, `sqlviewer`, `dump-debugger`, `hanger` and `worker`, not invented.

- **[WORKFLOW.md](WORKFLOW.md)** — the shape of the work: four routes, two axes, one loop.
- **[CONVENTIONS.md](CONVENTIONS.md)** — how you work, graded by evidence, with the sources.

## Install

```bash
claude plugin marketplace add KhaiStimpson/myworkflow
```

```bash
claude plugin install flow@myworkflow
```

Or, working from a local clone:

```bash
claude plugin marketplace add /path/to/myworkflow
claude plugin install flow@myworkflow
```

## The commands

Two you need to remember. Seven more underneath, for when you want to drive one stage by hand.

| | |
|---|---|
| `/flow` | **Macro.** Front door — routes the task, then runs the route end to end. |
| `/flow:go` | **Macro.** Advances the live effort by one task. Repeat, or hand to `/loop`. |

| | |
|---|---|
| `/flow:start` | Investigates, announces a route in three lines, one-token veto. |
| `/flow:explore` | Brainstorm with zero file changes → artifact of options with a recommendation. |
| `/flow:design` | Three variants, desktop + mobile, one HTML artifact → a decisions record that outranks the mockup. |
| `/flow:plan` | Phased checkbox plan in `docs/` **plus the loop prompt that executes it**. Implements nothing. |
| `/flow:work` | One slice, one branch, verify, screenshot, land on the integration branch. |
| `/flow:eyes` | Run it and look at it, both breakpoints — the pass green tests do not perform. |
| `/flow:wrap` | Handoff file, or integration PR + tracker comments + README with screenshots. |

Two agents run in the background: **`researcher`** (primary sources, inline citations, writes to
`docs/research/`) and **`fresh-eyes`** (reviews a slice on Standards and Spec before it merges).

## The short version

```
/flow <the task>   →  routes it, runs it
/flow:go           →  one task at a time, until the plan is done
```

Under the hood that is still `start → explore/design → plan → work → eyes → wrap`, and any of
those can be invoked directly when you want just that stage. Small work skips to route 0 and none
of it applies. That is the point of the front door.

## Design notes

**The routes match Orchestrator's four lanes on purpose.** Orchestrator (a separate, private repo)
specifies the automated version of this same model — conductors, spawned sessions, context packs,
status files. This is the hand-driven version: usable today, and a behavioural spec for what
Orchestrator has to reproduce.

**It encodes what you do, not what a methodology says.** The plan-plus-loop-prompt pairing, the
integration-branch topology, three variants at both breakpoints, "stop and ask rather than guess",
and the per-repo test posture all come from your own repeated words. Where the evidence was
contested — per-ticket versus batched review, test posture — the system asks once and records the
answer rather than picking for you.
