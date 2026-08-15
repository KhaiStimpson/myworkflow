# myworkflow

Your working loop, packaged as a Claude Code plugin — derived from ~40 of your sessions across
`andrew-crm`, `sqlviewer`, `dump-debugger`, `hanger` and `worker`, not invented.

- **[WORKFLOW.md](WORKFLOW.md)** — the shape of the work: four routes, two axes, one loop.
- **[CONVENTIONS.md](CONVENTIONS.md)** — how you work, graded by evidence, with the sources.

## Install

```bash
claude plugin marketplace add C:/Dev/repos/myworkflow
```

```bash
claude plugin install flow@myworkflow
```

## The commands

| | |
|---|---|
| `/flow:start` | Front door. Investigates, announces a route in three lines, one-token veto. |
| `/flow:explore` | Brainstorm with zero file changes → artifact of options with a recommendation. |
| `/flow:design` | Three variants, desktop + mobile, one HTML artifact → a decisions record that outranks the mockup. |
| `/flow:plan` | Phased checkbox plan in `docs/` **plus the loop prompt that executes it**. Implements nothing. |
| `/flow:work` | One slice, one branch, verify, screenshot, land on the integration branch. |
| `/flow:eyes` | Run it and look at it, both breakpoints — the pass green tests do not perform. |
| `/flow:wrap` | Handoff file, or integration PR + tracker comments + README with screenshots. |

Two agents run in the background: **`researcher`** (primary sources, inline citations, writes to
`docs/research/`) and **`fresh-eyes`** (reviews a slice on Standards and Spec, on sonnet).

## The short version

```
/flow:start  →  explore / design (if the answer is a picture)
             →  /flow:plan  →  paste the generated prompt after /loop or /goal
             →  /flow:work per task  →  /flow:eyes  →  /flow:wrap
```

Small work skips straight to route 0 and none of this applies. That is the point of the front
door.

## Design notes

**The routes match Orchestrator's four lanes on purpose.**
[`worker/.scratch/orchestrator/spec.md`](../worker/.scratch/orchestrator/spec.md) specifies the
automated version — conductors, spawned sessions, context packs, status files. This is the
hand-driven version of the same model: usable today, and a behavioural spec for what Orchestrator
has to reproduce.

**It encodes what you do, not what a methodology says.** The plan-plus-loop-prompt pairing, the
integration-branch topology, three variants at both breakpoints, "stop and ask rather than guess",
and the per-repo test posture all come from your own repeated words. Where the evidence was
contested — per-ticket versus batched review, test posture — the system asks once and records the
answer rather than picking for you.
