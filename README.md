# myworkflow

Your working loop, packaged as a Claude Code plugin — derived from ~40 of your sessions across
`andrew-crm`, `sqlviewer`, `dump-debugger`, `hanger` and `worker`, not invented.

- **[WORKFLOW.md](WORKFLOW.md)** — the shape of the work: four routes, two axes, one loop.
- **[CONVENTIONS.md](CONVENTIONS.md)** — how you work, graded by evidence, with the sources.

## Install

`flow` depends on [`mattpocock-skills`](https://github.com/mattpocock/skills) for its foggy
route, so add that marketplace **first** — a declared dependency that cannot be resolved leaves
`flow` disabled until it is:

```bash
claude plugin marketplace add mattpocock/skills
```

Then:

```bash
claude plugin marketplace add KhaiStimpson/myworkflow
claude plugin install flow@myworkflow
```

Installing `flow` pulls in `mattpocock-skills` automatically, and enabling `flow` enables it too.

Or, working from a local clone:

```bash
claude plugin marketplace add /path/to/myworkflow
claude plugin install flow@myworkflow
```

### Configuration

| Option | Default | What it does |
|---|---|---|
| **Foggy-route skill** | `mattpocock-skills:grill-me` | The skill route 3 invokes when something material is still undecided. Set it to `mattpocock-skills:wayfinder` when the work spans more sessions than one agent can hold and you want decision tickets on a tracker. |

## The commands

Two you need to remember. Seven more underneath, for when you want to drive one stage by hand.

| | |
|---|---|
| `/flow` | **Macro.** Front door — routes the task, then runs the route end to end. |
| `/flow:loop` | **Macro.** Starts the loop that executes the live plan — fills the loop prompt in from the plan and hands it to `/loop`. After a fog session it spawns a fresh background agent instead. |

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

**Every agent this flow spawns starts on fresh context — never a fork of the conversation.** No
skill here uses `context: fork`, and nothing spawns `subagent_type: fork`. A forked reviewer
inherits the reasoning that wrote the code and agrees with it; a forked loop re-reads the whole
transcript on every iteration to learn what the plan file already says.

## One phase, one session

A phase decides how long a session lives. When the loop ticks the last task under a `## Phase`, the
session commits, updates the handoff and stops; the next phase starts on fresh context, reading the
plan and the handoff and nothing else.

This is the one rule here that came from measurement rather than from mined habit. Across six
sessions costing ~$1,116, **81% of spend was cache reads**. In the worst of them, an iteration cost
$3–8 while context sat under ~260K and **$17–124 above it** for the same kind of work — and after
it auto-compacted from 992K down to 89K, iterations went straight back to $5–7. So phases are sized
to **five to seven tasks**, which is what fits under that knee, and `/flow:plan` enforces it.

Evidence, corrections to an earlier analysis, and the real downsides:
[`docs/spec-session-economics.md`](docs/spec-session-economics.md). Re-derive the numbers yourself
with `python scripts/measure-sessions.py`.

## The hooks

Some rules are enforced by hooks rather than prose, so they hold regardless of which model is
driving. Each exits silently when it does not apply — a repo with no live effort pays nothing.

| | When | What it does |
|---|---|---|
| **Session state** | session start / resume | Injects the live effort, phase, next unchecked task, branch, and where context sits against its budget. Resuming costs no keystrokes. |
| **Phase boundary** | end of turn | Detects that the last task in a phase is ticked and says to commit, update the handoff and hand off to a fresh session. The loop prompt runs the same check explicitly; the hook is belt and braces. |
| **Context backstop** | end of turn | Fires at 250K — the measured cost knee — which a correctly sized phase never reaches. It exists for the runaway *task* a phase boundary cannot catch — one measured iteration burned 257 turns and $124 on its own. |
| **Image read guard** | before `Read` | Blocks a large screenshot read and hands back the path and size instead. One measured session spent 96% of everything it observed on 63 image reads. `touch .flow/see` to read one deliberately; the marker is consumed by that read. |
| **Handoff spine** | session end, pre-compact | Writes branch, SHA, phase, chain position, next task and dirty files into `HANDOFF-<effort>.md`, between markers. It never touches the prose sections — a hook cannot write "what must not be re-litigated", and `/flow:wrap` still owns those. |

`scripts/run-gated.sh` is not a hook but belongs here: wrap your build and test commands in it and a
green run costs one line instead of a thousand, with the full log on disk and failures shown in
full.

The scripts are POSIX `sh`. **On Windows they need Git Bash**, which is how Claude Code runs
hooks there. `sh tests/run-tests.sh` exercises them against a throwaway fixture.

## The short version

```
/flow <the task>   →  routes it, runs it
/flow:loop         →  starts the loop that walks the plan to done
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

## Credits

Route 3 — the foggy route, where something material is still undecided — is answered by
**[Matt Pocock's skills](https://github.com/mattpocock/skills)**, declared as a plugin
dependency. Nothing is vendored, forked or copied; the plugin is installed alongside this one and
updates on his schedule.

- **`grill-me`** (the default) interviews a plan until every design branch resolves.
- **`wayfinder`** (optional) plans work spanning many sessions as decision tickets on a tracker.

MIT License, © 2026 Matt Pocock — [github.com/mattpocock/skills](https://github.com/mattpocock/skills)
· [aihero.dev](https://www.aihero.dev)
