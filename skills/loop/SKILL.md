---
name: loop
description: Start the loop that executes the live plan — read the plan, fill in the loop prompt from the template, and hand it to /loop. Use to run a planned effort to completion or to resume one, instead of pasting the loop prompt by hand.
argument-hint: [optional interval, e.g. 10m]
model: sonnet
effort: medium
---

The plan file is the state; the loop is the stateless engine that walks it. This skill's job is
to start that engine correctly — **not** to implement a task itself.

## Where the effort stands

- Effort: !`cat .flow/current 2>/dev/null || echo none`
- Branch: !`git branch --show-current 2>/dev/null || echo "(not a git repo)"`
- Working tree: !`git status --porcelain 2>/dev/null | head -20 || echo clean`
- Plan files: !`ls docs/*-plan.md 2>/dev/null || echo none`
- Next task: !`grep -h -m1 -- '- \[ \]' docs/*-plan.md 2>/dev/null || echo "none - all checked"`
- Remaining: !`grep -hc -- '- \[ \]' docs/*-plan.md 2>/dev/null || echo 0`
- Fog marker: !`cat .flow/fog 2>/dev/null || echo none`
- Handoff: !`ls HANDOFF-*.md 2>/dev/null || echo none`
- Phase this session owns: !`cat .flow/phase 2>/dev/null || echo none`
- Handoff pending: !`cat .flow/handoff-pending 2>/dev/null || echo none`
- Phase of the next task: !`cat docs/*-plan.md 2>/dev/null | sed -n '/^## Phase/h; /^[[:space:]]*- \[ \]/{x;/./{p;q};q}' | grep . || echo none`

Requested interval: **$ARGUMENTS** — empty means let the runner self-pace, which is what
implementation work wants.

## Decide whether there is a loop to start

**No effort and no plan file** → there is nothing to loop over. Say so and offer `/flow` instead.
Do not invent an effort, and do not start looping on a plan you wrote in this same turn without
saying so.

**Next task is "none - all checked"** → the plan is complete. Say so and invoke `wrap` for
ending B. Do not start a loop that would immediately stop itself.

**A handoff file exists** → read it before anything else, and carry its "do not re-litigate"
section into the prompt you build. Re-deciding a settled question is the expensive failure here.

**The plan has gone stale against the tree** — tasks describing code that no longer exists, or a
base app finished after the plan was written — say so and re-run `plan` against the current repo.
A loop reconciling a stale plan task by task costs more than rewriting it.

## Build the prompt, do not improvise it

Read `${CLAUDE_PLUGIN_ROOT}/templates/loop-prompt.md` and fill the anatomy in with the real
values from this repo:

- the actual plan path, `docs/<effort>-plan.md`
- the actual build and test commands, taken from the plan's **Ground rules** — never guessed, and
  never a test posture the effort decided against
- the **UI variant** if any remaining task touches something a person can see
- the **tracker variant** if the effort has issues
- the **handoff variant** whenever the loop will run unattended, which is the default here

**Do not reconstruct the prompt from memory.** A paraphrase is exactly how the plan and its
engine drift apart, and the template is the one place the anatomy lives.

## Pick the runner

Two runners. **Fresh context is the default; looping here is the exception** — take route A only
when this conversation has nothing worth escaping.

### A — a clean start: loop in this session

Invoke the **bundled** `loop` skill — the one named `loop`, not this one — with the interval
first and the filled-in prompt after it:

```
<interval, or nothing at all> <the filled-in loop prompt>
```

Omit the interval unless `$ARGUMENTS` gave one. Implementation iterations should follow each
other as fast as the work allows, not sit on a timer.

Take this route only when **both** are true: the fog marker is `none` and no fog skill ran in this
conversation, **and** the handoff records no completed phase. That means this is the effort's first
session and there is nothing behind you worth leaving.

### B — spawn a fresh background agent

Take this route when **either** is true:

- **A fog session came first** — the marker above is anything but `none`, or the fog skill ran
  earlier in this conversation. This conversation is carrying an interview, and re-reading every
  resolved branch on every iteration buys nothing: what survived is already in the plan.
- **A phase boundary ended the last session** — the *handoff pending* line above is anything but
  `none`, the handoff records a completed phase, or `scripts/phase-boundary.sh` reported one in
  this conversation. The previous phase's transcript is
  spent; its conclusions are in the plan and the handoff.

Either way, **spawn one background agent on fresh context** with the Agent tool:

- `subagent_type: general-purpose`
- `run_in_background: true`
- prompt: the filled-in loop prompt, plus the plan path and the handoff path, plus the successor
  variant from the template — work this phase only, hand off at its boundary.

It starts cold and reads the plan, which is the point.

Then report the agent's name in one line, say the plan file is where progress shows, and stop.
Do not shadow it by starting a second loop here.

**One agent at a time.** Each session runs one phase and spawns one successor. Phases run in
sequence against committed state — never two agents on the plan at once. That is the difference
between this and the fan-out topology the research rejected, and it is not a detail: two agents
sharing a plan file will tick each other's boxes.

**Announce which runner you picked and why, in one line.** The user overrides it with a word — if
they say to carry on in this session, do that and say what it will cost.

## Subagents here start fresh, never forked

Anything this flow spawns — the loop agent above, `researcher`, `fresh-eyes`, `eyes`, an
`Explore` pass — is a **new agent on fresh context**. Never `context: fork` in frontmatter, never
`subagent_type: fork`. A forked context inherits this conversation's history, which is the thing
we are deliberately not paying for, and it makes the agent's report an echo of what the parent
already believed rather than an independent read.

## The rules that make this safe to run unattended

- **One task per iteration.** No batching two because they look related, no skipping ahead.
- **Ambiguous, blocked, or needing a decision that is not the loop's → stop and ask.** This is
  the clause the whole unattended posture rests on; it must survive into the prompt verbatim.
- **The tick is the progress record.** An iteration that implements without ticking makes the
  next one repeat the work.
- **The loop stops at two levels.** End of *phase* — hand off to a fresh session. End of *plan* —
  terminate, and `wrap` runs, not another loop. `scripts/phase-boundary.sh` tells the loop which
  of the two it has reached, so nobody has to count tasks.

## Never hand back a command

Start the loop yourself. The only thing the user should have to type is `/flow` or `/flow:loop`.
