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

Two runners, and the fog marker decides between them.

### A — no fog before this: loop in this session

Invoke the **bundled** `loop` skill — the one named `loop`, not this one — with the interval
first and the filled-in prompt after it:

```
<interval, or nothing at all> <the filled-in loop prompt>
```

Omit the interval unless `$ARGUMENTS` gave one. Implementation iterations should follow each
other as fast as the work allows, not sit on a timer.

### B — fog came first: spawn a fresh background agent

If the fog marker above is anything but `none`, or the fog skill ran earlier in **this**
conversation, do not loop here. This conversation is carrying an interview — every branch that
was resolved, every option that was rejected — and re-reading all of it on every iteration buys
nothing, because the decisions that survived it are already written into the plan.

Instead **spawn one background agent on fresh context** with the Agent tool:

- `subagent_type: general-purpose`
- `run_in_background: true`
- prompt: the filled-in loop prompt, plus the plan path, plus
  `Repeat this until every checkbox in the plan is ticked, then stop.`

It starts cold and reads the plan, which is the point — the plan and the handoff carry everything
the interview settled, and nothing it did not.

Then report the agent's name in one line, say the plan file is where progress shows, and stop.
Do not shadow it by starting a second loop here.

**Announce which runner you picked and why, in one line.** The user overrides it with a word.

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
- **The loop terminates itself** when every box is checked. Then `wrap` runs, not another loop.

## Never hand back a command

Start the loop yourself. The only thing the user should have to type is `/flow` or `/flow:loop`.
