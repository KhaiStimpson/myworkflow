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

## The hooks

Four rules are enforced by hooks rather than prose, so they hold regardless of which model is
driving. Each exits silently when it does not apply — a repo with no live effort pays nothing.

| | When | What it does |
|---|---|---|
| **Session state** | session start / resume | Injects the live effort, phase, next unchecked task and branch. Resuming costs no keystrokes. |
| **Screenshot gate** | before `git commit` | Blocks a commit staging UI files when `docs/screenshots/<slug>/` is empty. Override with `[skip-eyes]` in the message. |
| **Branch guard** | before `git push` / `git merge` | Blocks anything targeting `dev` or `main` while an integration branch is live. Blocks migration re-scaffold and squash, in repos that have migrations. |
| **Handoff spine** | session end, pre-compact | Writes branch, SHA, phase, next task and dirty files into `HANDOFF-<effort>.md`, between markers. It never touches the prose sections — a hook cannot write "what must not be re-litigated", and `/flow:wrap` still owns those. |

The scripts are POSIX `sh`. **On Windows they need Git Bash**, which is how Claude Code runs
hooks there.

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

## Credits

Route 3 — the foggy route, where something material is still undecided — is answered by
**[Matt Pocock's skills](https://github.com/mattpocock/skills)**, declared as a plugin
dependency. Nothing is vendored, forked or copied; the plugin is installed alongside this one and
updates on his schedule.

- **`grill-me`** (the default) interviews a plan until every design branch resolves.
- **`wayfinder`** (optional) plans work spanning many sessions as decision tickets on a tracker.

MIT License, © 2026 Matt Pocock — [github.com/mattpocock/skills](https://github.com/mattpocock/skills)
· [aihero.dev](https://www.aihero.dev)
