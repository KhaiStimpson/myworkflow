# Running long Claude Code implementation sessions economically

Research date: 2026-08-22. Local environment: Claude Code v2.1.239 (verified by running `claude --version`), Windows 11, models Opus 5 / Sonnet 5 / Haiku 4.5.

All prices and mechanics below are from Anthropic primary docs, cited inline. Where I could not find a primary source, it is marked **UNVERIFIED**.

---

## 1. Verdict

**Do not run one 1500-turn session that grows to 1M tokens. Cost scales with the integral of context size over turns, and there is no plateau — every turn re-reads the whole conversation at the cache-read rate.** A 1500-turn Opus 5 session growing 40k → 1M costs roughly **$460** in cache reads + output; the same 1500 turns split into ten 150-turn sessions each capped near 200k costs roughly **$160** — about **2.9x cheaper for identical work** (my arithmetic from published rates; method in §3).

The four levers that matter, in order of impact:

1. **Cap context, not turns.** Split at task boundaries with `/clear`; a fresh session resets the per-turn cache-read tax to near zero. Claude Code's docs name "long sessions that were never cleared" and "Opus left as the default model" as the two usual causes of unexpectedly high spend ([Manage costs](https://code.claude.com/docs/en/costs#when-a-developer-asks-about-a-limit)).
2. **Model choice.** Opus 5 is exactly **2.5x** Sonnet 5 on every token category ($5/$25 vs $2/$10 per MTok) ([Pricing](https://platform.claude.com/docs/en/about-claude/pricing)). Anthropic's own guidance: Sonnet for mechanical implementation against a written plan, Opus for ambiguity ([Model & effort guide](https://claude.com/blog/claude-model-and-effort-level-in-claude-code), 2026-07-07).
3. **Delegate verbose reads to subagents, but do not fan out sequential dependent implementation work.** Anthropic's measured multiplier: multi-agent systems use **~15x more tokens than chat**, agents ~4x ([Multi-agent research system](https://www.anthropic.com/engineering/multi-agent-research-system), 2025-06-13). Claude Code agent teams measure at **~7x a standard session** ([Manage costs](https://code.claude.com/docs/en/costs#manage-agent-team-costs)).
4. **Never change model, effort level, or the tool set mid-session.** Each is part of the cache key; changing one recomputes the entire conversation uncached ([How Claude Code uses prompt caching](https://code.claude.com/docs/en/prompt-caching#actions-that-invalidate-the-cache)).

---

## 2. What changes because of this (findings that move the decision)

### 2.1 The premise "one-subagent-per-phase for sequential implementation" is contradicted by Anthropic's own docs

You asked whether Anthropic recommends one subagent per phase for sequential implementation work with inter-phase dependencies. **It recommends the opposite.** The subagents page lists, under *"Use your main conversation when"*:

> "Multiple phases share significant context (planning → implementation → testing)"
> "The task needs frequent back-and-forth or iterative refinement"
> ([Create custom subagents](https://code.claude.com/docs/en/sub-agents))

And the agent-teams page:

> "For sequential tasks, same-file edits, or work with many dependencies, a single session or subagents are more effective."
> ([Orchestrate teams](https://code.claude.com/docs/en/agent-teams#when-to-use-agent-teams))

And the multi-agent research post names the unsuitable domains explicitly: "tasks requiring shared context across all agents", "workflows with extensive interdependencies between agents", "most coding tasks [have] limited parallelizable components" ([Multi-agent research system](https://www.anthropic.com/engineering/multi-agent-research-system)).

A phase-per-subagent implementation pipeline pays the full cold-start cost for each phase (each subagent's first request gets **no** cache hits from the parent — see §4.3) and loses the shared state that dependent phases need. The documented pattern for sequential phases is: **one main thread + a written plan file + subagents only for read-heavy side quests and adversarial review.**

### 2.2 There is no documented numeric rule for "split the session at N tokens"

I could not find any Anthropic-published token threshold at which to abandon a session. What *is* documented is behavioural:

- `/clear` "between unrelated tasks" ([Best practices](https://code.claude.com/docs/en/best-practices#manage-context-aggressively)).
- "If you've corrected Claude more than twice on the same issue in one session, the context is cluttered with failed approaches. Run `/clear`... A clean session with a better prompt almost always outperforms a long session with accumulated corrections." ([Best practices](https://code.claude.com/docs/en/best-practices#course-correct-early-and-often))
- "Once the spec is complete, start a fresh session to execute it." ([Best practices](https://code.claude.com/docs/en/best-practices#let-claude-interview-you))
- Quality argument, not just cost: "LLM performance degrades as context fills... Claude may start 'forgetting' earlier instructions or making more mistakes." ([Best practices](https://code.claude.com/docs/en/best-practices)) Anthropic's context-engineering post calls this *context rot*: "as the number of tokens in the context window increases, the model's ability to accurately recall information from that context decreases" ([Effective context engineering](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents), 2025-09-29).

**Status: no primary numeric threshold exists. UNVERIFIED as a documented rule.** §3 gives the arithmetic to set your own.

### 2.3 Claude Code *does* prune tool results mid-session, before it compacts

> "Claude Code manages context automatically as you approach the limit. **It clears older tool outputs first, then summarizes the conversation if needed.**"
> ([How Claude Code works](https://code.claude.com/docs/en/how-claude-code-works#when-context-fills-up))

So yes — tool results are pruned mid-session, automatically, ahead of full compaction. There is no user-facing command documented to trigger it manually. The underlying API primitive is `clear_tool_uses_20250919` ([Context editing](https://platform.claude.com/docs/en/build-with-claude/context-editing)), which is exposed to API/SDK callers, not as a Claude Code slash command. **UNVERIFIED:** whether Claude Code's tool-output clearing is literally that API feature or a client-side equivalent — the Claude Code docs don't say.

Worth knowing if you use the API/SDK directly: tool-result clearing **invalidates the cached prefix at the clearing point**, so you pay a cache write each time it fires. The `clear_at_least` parameter exists to ensure enough tokens are freed to justify that. Defaults: trigger at 100,000 input tokens, keep the 3 most recent tool uses, clear results but not tool inputs ([Context editing](https://platform.claude.com/docs/en/build-with-claude/context-editing)).

### 2.4 Sonnet 5 quietly became the cheapest good option

Sonnet 5 is **$2 / $10** per MTok, down from Sonnet 4.6's $3/$15. The introductory-pricing note is now permanent:

> "The $2/$10 per million input/output token pricing for Claude Sonnet 5, announced at launch as introductory pricing through August 31, 2026, is now the standard price. The previously scheduled increase to $3/$15 per million input/output tokens on September 1, 2026 will not occur."
> ([Pricing](https://platform.claude.com/docs/en/about-claude/pricing))

Sonnet 5 also runs at a native 1M context on the Anthropic API with **no premium above 200k** and no `[1m]` variant to select ([Model configuration](https://code.claude.com/docs/en/model-config#sonnet-5-context-window); [Pricing → long context](https://platform.claude.com/docs/en/about-claude/pricing)). That makes Sonnet 5 the default choice for long implementation runs on cost *and* window.

Caveat that cuts the other way: **Claude 4.7-and-later models use a new tokenizer that produces ~30% more tokens for the same text** ([Pricing](https://platform.claude.com/docs/en/about-claude/pricing)). Opus 5 and Sonnet 5 are both on it, so per-MTok comparisons against Sonnet 4.6 understate the newer models' effective cost by roughly that factor.

---

## 3. Prompt-cache economics in a long session

### 3.1 Billing mechanics (from [Prompt caching](https://platform.claude.com/docs/en/build-with-claude/prompt-caching) and [Pricing](https://platform.claude.com/docs/en/about-claude/pricing))

| Operation | Multiplier on base input | Duration |
|---|---|---|
| 5-minute cache write | **1.25x** | 5 minutes |
| 1-hour cache write | **2x** | 1 hour |
| Cache read (hit) / refresh | **0.1x** | same as preceding write |

`total_input_tokens = cache_read_input_tokens + cache_creation_input_tokens + input_tokens`. Cache reads are billed at 10% of base input — they are **not free**.

Break-even, quoted verbatim: "caching pays off after one cache read for the 5-minute duration (1.25x write), or after two cache reads for the 1-hour duration (2x write)."

TTL timing rule: "The lifetime is measured from the start of the request that writes or reads the cache entry, not from the end of its response. Time spent generating a response counts against the lifetime: if a response takes 4 minutes to stream, a follow-up request that reuses the same cached prefix must start within about 1 minute of that response completing." Each hit resets the timer ([Claude Code prompt caching → Cache lifetime](https://code.claude.com/docs/en/prompt-caching#cache-lifetime)).

Which TTL Claude Code picks for you:
- **Claude subscription:** 1-hour TTL automatically; drops to 5-minute once you're drawing on usage credits, unless you set `ENABLE_PROMPT_CACHING_1H=1`.
- **API key / Bedrock / Agent Platform / Foundry / Claude Platform on AWS:** 5 minutes by default; opt in with `ENABLE_PROMPT_CACHING_1H=1`. Force short with `FORCE_PROMPT_CACHING_5M=1`.

([Claude Code prompt caching](https://code.claude.com/docs/en/prompt-caching#cache-lifetime))

Minimum cacheable prefix: **512 tokens** on Opus 5, **1,024** on Sonnet 5, **4,096** on Haiku 4.5 ([Prompt caching](https://platform.claude.com/docs/en/build-with-claude/prompt-caching)). Max 4 explicit breakpoints per request.

### 3.2 Quantified: one turn at 1M cached context vs one turn at 50k

Assumptions, stated so you can re-run them: 1,500 new input tokens per turn written at the 5m rate, 1,500 output tokens per turn, everything else a cache read. Prices from the pricing page above.

| Model | Context | Cache read | New-token write (5m) | Output | **Turn total** |
|---|---|---|---|---|---|
| Opus 5 | 50k | $0.0250 | $0.0094 | $0.0375 | **$0.072** |
| Opus 5 | 200k | $0.1000 | $0.0094 | $0.0375 | **$0.147** |
| Opus 5 | 500k | $0.2500 | $0.0094 | $0.0375 | **$0.297** |
| Opus 5 | **1M** | $0.5000 | $0.0094 | $0.0375 | **$0.547** |
| Sonnet 5 | 50k | $0.0100 | $0.0037 | $0.0150 | **$0.029** |
| Sonnet 5 | **1M** | $0.2000 | $0.0037 | $0.0150 | **$0.219** |
| Haiku 4.5 | 50k | $0.0050 | $0.0019 | $0.0075 | **$0.014** |
| Haiku 4.5 | **1M** | $0.1000 | $0.0019 | $0.0075 | **$0.109** |

**Headline: on Opus 5, a turn at 1M cached context costs ~7.6x a turn at 50k ($0.547 vs $0.072).** Read-only, the ratio is exactly 20x ($0.50 vs $0.025) — output cost is what dilutes it. On Sonnet 5 the same turn is $0.219 vs $0.029 (7.6x), i.e. **a 1M-context Sonnet 5 turn is still cheaper than a 200k-context Opus 5 turn.**

### 3.3 Quantified: the 1500-turn session

Same assumptions, context growing linearly:

| Shape | Opus 5 | Sonnet 5 |
|---|---|---|
| **1 session, 1500 turns, 40k → 1M** | **$460** | **$184** |
| **10 sessions x 150 turns, each 40k → 200k** | **$160** | **$64** |

The split saves ~2.9x on either model. Note that the split figure ignores the re-priming cost of each new session (re-reading the plan file, CLAUDE.md, key files) — call it 20–40k tokens of fresh input per session, ~$0.15–0.25 on Opus 5 per restart, which is noise against the $300 saved.

*These are my calculations from Anthropic's published rates, not figures Anthropic publishes. The rates are cited; the arithmetic is mine.*

### 3.4 The cold-miss cliff

If the cache expires (break longer than the TTL) the next request reprocesses the whole history as uncached input:

| | Opus 5 | Sonnet 5 |
|---|---|---|
| 1M reprocessed at base input | $5.00 | $2.00 |
| 1M re-written, 5m TTL (1.25x) | $6.25 | $2.50 |
| 1M re-written, 1h TTL (2x) | $10.00 | $4.00 |

So a single coffee break in a 1M-token API-key session costs about **$6** on Opus 5 before you get a single token of work. Claude Code's docs name this explicitly: "your first message after a break longer than the cache lifetime misses the cache and reprocesses your full context" ([Manage costs → Why usage climbs](https://code.claude.com/docs/en/costs#why-usage-climbs-in-a-long-session)).

Worse: **resuming a session after a Claude Code upgrade reprocesses everything with no cache hits**, because the system prompt changed — "the first turn back into a long session can be the most expensive request you send" ([Claude Code prompt caching](https://code.claude.com/docs/en/prompt-caching#upgrading-claude-code)). Set `DISABLE_AUTOUPDATER=1` if you plan to resume long sessions.

### 3.5 What silently burns tokens while you're idle

From [Why usage climbs in a long session](https://code.claude.com/docs/en/costs#why-usage-climbs-in-a-long-session) — each of these sends your **full context** on a session that looks idle:

- Scheduled tasks firing on their interval
- Cross-session messages delivered as a new turn (`crossSessionInbound: hold` to suppress)
- `/goal` background check-ins (`CLAUDE_CODE_GOAL_CHECKIN_MINUTES=0` to disable)
- Active agent teammates, which "keep consuming tokens until [they] exit"
- Background summarization for `--resume` and `/usage` status checks — "typically under $0.04 per session"

`/compact` is itself a large request: it "reads the conversation it summarizes". Warm, it reads your prefix from cache and costs "a fraction of what the context size suggests"; cold, it reprocesses the full history uncached. `/clear` costs nothing ([Manage costs](https://code.claude.com/docs/en/costs#why-usage-climbs-in-a-long-session); [Compacting the conversation](https://code.claude.com/docs/en/prompt-caching#compacting-the-conversation)).

### 3.6 The mid-session actions that torch your cache

Full list at [Actions that invalidate the cache](https://code.claude.com/docs/en/prompt-caching#actions-that-invalidate-the-cache):

- **Switching model** (`/model`) — each model has its own cache; full re-read.
- **Changing effort level** (`/effort`) — effort is part of the cache key; full re-read.
- **Turning on fast mode** — adds a header that is part of the cache key; those uncached tokens are billed at fast-mode rates ($10/$50 per MTok on Opus 5, [Pricing → Fast mode](https://platform.claude.com/docs/en/about-claude/pricing)). Cost applies once per conversation.
- **Connecting/disconnecting an MCP server** — only when its tools load into the prefix; deferred tools (the default) are cache-safe.
- **Denying an entire tool** (bare `Bash`, `WebFetch`, `"*"`) — removes it from the system prompt; full re-read.
- **Compacting**, **upgrading Claude Code**.

**`opusplan` is a cache trap for long runs.** "The `opusplan` model setting resolves to Opus during plan mode and Sonnet during execution, so **each plan-mode toggle is a model switch and starts a fresh cache**" ([prompt caching](https://code.claude.com/docs/en/prompt-caching#switching-models)). If you toggle plan mode repeatedly in a large session, you pay a full uncached re-read every time. Use it at the top of a session, not throughout one.

Cache-safe (append-only, prefix intact): editing repo files, invoking skills and commands, changing permission mode, `/recap`, `/rewind`, spawning a subagent, plugin skills/commands/agents/hooks. **`/rewind` beats `/compact`** for abandoning a bad path: "Rewinding truncates back to a prefix that is already cached, rather than building a new one as compaction does."

Cache scope is per machine **and per directory** — "two sessions in different directories build different prefixes and miss each other's cache. That includes worktrees of the same repository." Parallel sessions in the *same* directory share cache ([Cache scope](https://code.claude.com/docs/en/prompt-caching#cache-scope)).

Anthropic's own rules of thumb from the Claude Code team ([Lessons from building Claude Code: prompt caching is everything](https://claude.com/blog/lessons-from-building-claude-code-prompt-caching-is-everything), 2026-04-30): never change models mid-session; never add/remove tools mid-conversation; pass information updates via messages, not system-prompt edits; monitor cache hit rate like a critical infra metric.

---

## 4. Subagent / background-agent topology

### 4.1 The published multipliers

| Figure | Source |
|---|---|
| Agents use **~4x more tokens than chat** | [Multi-agent research system](https://www.anthropic.com/engineering/multi-agent-research-system) (2025-06-13) |
| Multi-agent systems use **~15x more tokens than chats** | same |
| Claude Code **agent teams ~7x a standard session** when teammates run in plan mode | [Manage costs](https://code.claude.com/docs/en/costs#manage-agent-team-costs) |
| Multi-agent (Opus 4 lead + Sonnet 4 subagents) beat single-agent Opus 4 by **90.2%** on Anthropic's internal research eval | [Multi-agent research system](https://www.anthropic.com/engineering/multi-agent-research-system) |
| Token usage alone explained **80%** of performance variance on browsing evals; three factors (tokens, tool calls, model choice) explained **95%** | same |

Note the 15x/90.2% pair is from a **research** system, not a coding one, and Anthropic says so: the economics "make sense" only "for valuable tasks that involve heavy parallelization, information that exceeds single context windows, and interfacing with numerous complex tools."

### 4.2 What belongs in a subagent vs the main thread

Verbatim from [Create custom subagents](https://code.claude.com/docs/en/sub-agents):

**Subagent when:** the task produces verbose output (logs, search results, file contents) you won't reference again; you want tool restrictions or a permission mode; the work is self-contained and can return a summary; you need parallel operations with independent contexts.

**Main conversation when:** frequent back-and-forth or iterative refinement; **multiple phases share significant context (planning → implementation → testing)**; quick targeted changes; latency matters ("subagents start fresh and gather context").

Concrete high-value delegations named in the docs: run the full test suite and report only failures; fetch docs; process log files ([Manage costs → Delegate verbose operations](https://code.claude.com/docs/en/costs#delegate-verbose-operations-to-subagents)). And the adversarial review step: a reviewer subagent "sees only the diff and the criteria you give it, not the reasoning that produced the change" ([Best practices](https://code.claude.com/docs/en/best-practices#add-an-adversarial-review-step)) — with the warning that a reviewer told to find gaps will find them, so scope it to correctness only.

Built-in subagents: **Explore** (model inherited, capped at Opus; read-only search), **Plan**, **general-purpose**. Explore and Plan "skip CLAUDE.md files and git status to keep research fast and inexpensive"; all other subagents load both ([Create custom subagents](https://code.claude.com/docs/en/sub-agents)).

Per-subagent knobs relevant to cost: `model` (`sonnet`/`opus`/`haiku`/`fable`/full ID/`inherit`), `effort`, `maxTurns`, `tools`/`disallowedTools`, `permissionMode`, `background`, `isolation: worktree`.

### 4.3 The cache cost of a subagent, and the fork alternative

> "A subagent starts its own conversation with its own system prompt and tool set, separate from the parent's. **Its first request doesn't read the parent's cache**... **Subagents use the five-minute TTL even on a subscription**, since the automatic one-hour TTL applies to the main conversation."
> ([Subagents and the cache](https://code.claude.com/docs/en/prompt-caching#subagents-and-the-cache))

By contrast, **`/subtask` (a fork)** "inherits the parent's system prompt, tools, and conversation history exactly, so its first request reads the parent's cache" — the docs call it "cheaper than a fresh subagent" ([Fork the conversation](https://code.claude.com/docs/en/sub-agents)). For a side task that needs your existing context, fork; for a task that needs *none* of it, spawn.

Also: in a workflow fan-out of same-prefix agents, "Claude Code briefly holds all but the first so their first requests can read the prefix the first agent cached."

Background subagents get a restricted tool set: Read, Grep, Glob, Bash, PowerShell, Edit, Write, WebFetch, WebSearch, Skill, and MCP tools only. Nesting is allowed to 3 layers by default (`CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH`).

### 4.4 Failure modes, documented

From [Multi-agent research system](https://www.anthropic.com/engineering/multi-agent-research-system):
- spawning excessive subagents for simple queries
- **duplicate work across agents investigating identical angles**
- subagents pursuing tangential information endlessly
- vague task descriptions causing misalignment

From [Orchestrate teams](https://code.claude.com/docs/en/agent-teams):
- **"Two teammates editing the same file leads to overwrites. Break the work so each teammate owns a different set of files."** — the write-heavy coordination failure, stated plainly.
- Task status lags; teammates fail to mark tasks complete, blocking dependents.
- Teammates "don't inherit the lead's conversation history."
- Idle notifications "don't carry the teammate's output."
- Known limitations: no session resumption with in-process teammates; no nested teams; lead is fixed; permissions set at spawn.
- **Enabling agent teams changes ordinary delegation**: a subagent Claude names launches as a *teammate*, and "an orchestration flow that waits on subagent results can stall." If you orchestrate with subagents, keep `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=0`.

Sizing guidance when teams *are* right: start with 3–5 teammates; "if you have 15 independent tasks, 3 teammates is a good starting point"; "three focused teammates often outperform five scattered ones"; use Sonnet for teammates; shut teammates down when done; keep spawn prompts focused, since teammates load CLAUDE.md, MCP servers and skills automatically on top of whatever you put in the prompt.

### 4.5 Verdict on topology for sequential implementation

**Recommended shape (the shape is my recommendation; every component is documented):**

```
Session 1 (Opus 5, plan mode) → interview + SPEC.md / PLAN.md written to disk
   ↓  /clear  or a new session entirely
Session 2..N (Sonnet 5, one per phase or per 100-200 turns)
   ├─ reads PLAN.md as the state carrier
   ├─ Explore subagent for "where is X" questions
   ├─ subagent for test-suite runs → failures only
   ├─ implements, verifies against a runnable check
   ├─ updates PLAN.md with what's done / what's next
   └─ adversarial review subagent against PLAN.md before "done"
```

The plan-file-as-state pattern is Anthropic's: "Once the spec is complete, start a fresh session to execute it. The new session has clean context focused entirely on implementation, and you have a written spec to reference" ([Best practices](https://code.claude.com/docs/en/best-practices#let-claude-interview-you)). The most useful specs are "self-contained: they name the files and interfaces involved, state what is out of scope, and end with an end-to-end verification step." The context-engineering post generalises it as structured note-taking — external memory files that survive context resets, with subagents returning "condensed summaries (typically 1,000-2,000 tokens)" to the coordinator ([Effective context engineering](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents)).

Where parallel agents *do* pay off in a coding run: parallel code review across independent lenses, competing-hypothesis debugging, and new modules that own disjoint file sets ([agent teams use cases](https://code.claude.com/docs/en/agent-teams#use-case-examples)).

---

## 5. Model selection

### 5.1 Current published prices (all [Pricing](https://platform.claude.com/docs/en/about-claude/pricing), fetched 2026-08-22)

| Model | Input | 5m cache write | 1h cache write | Cache hit/refresh | Output |
|---|---|---|---|---|---|
| Claude Fable 5 | $10 | $12.50 | $20 | $1.00 | $50 |
| Claude Mythos 5 (limited availability) | $10 | $12.50 | $20 | $1.00 | $50 |
| **Claude Opus 5** | **$5** | **$6.25** | **$10** | **$0.50** | **$25** |
| Claude Opus 4.8 / 4.7 / 4.6 / 4.5 | $5 | $6.25 | $10 | $0.50 | $25 |
| **Claude Sonnet 5** | **$2** | **$2.50** | **$4** | **$0.20** | **$10** |
| Claude Sonnet 4.6 / 4.5 | $3 | $3.75 | $6 | $0.30 | $15 |
| **Claude Haiku 4.5** | **$1** | **$1.25** | **$2** | **$0.10** | **$5** |

Per MTok, USD. Batch API is a flat **50% discount** on input and output (Opus 5 $2.50/$12.50; Sonnet 5 $1/$5; Haiku 4.5 $0.50/$2.50) but is not applicable to interactive Claude Code.

Ratios that matter: **Opus 5 = 2.5x Sonnet 5 = 5x Haiku 4.5**, uniformly across input, output, writes and reads.

Other modifiers that stack: `inference_geo: "us"` = **1.1x** on everything for 4.6+ models; regional/multi-region endpoints on Bedrock/Google Cloud = **10% premium**; fast mode on Opus 5 = **$10/$50** per MTok across the full window.

Reference point for budgeting from [Manage costs](https://code.claude.com/docs/en/costs): "Across enterprise deployments, the average cost is around $13 per developer per active day and $150-250 per developer per month, with costs remaining below $30 per active day for 90% of users."

### 5.2 Where Opus earns its price

Anthropic's guidance ([Choosing a Claude model and effort level in Claude Code](https://claude.com/blog/claude-model-and-effort-level-in-claude-code), 2026-07-07):

- **Opus** — "the expert tier, excelling at ambiguous problems requiring deep reasoning"; **Sonnet** — "the generalist, ideal for routine tasks with clear specifications."
- Implementation: "Opus at high effort" for best capability/thoroughness on multi-step work; "Sonnet at high effort" is "excellent for well-defined implementations when budget-conscious."
- Mechanical work: Sonnet at default effort — **"no reason to pay for capability the task doesn't need."** Explicit advice to *switch down to Sonnet when the work becomes routine, even if you started on a larger model.*
- Cost nuance worth carrying: "On complex tasks, larger models finish faster despite higher per-token pricing, potentially reducing total cost." Per-token price is not total cost.
- Diagnostic heuristic: did Claude "not know enough" (change model) or "not try hard enough" (raise effort)?
- Fable 5 is positioned as "a specialist who's seen problems almost no one else has" for subtle bugs and unfamiliar domains, and is said to excel on long runs — at $10/$50 per MTok, 2x Opus 5.

Claude Code's own cost page is blunter: "Sonnet handles most coding tasks well and costs less than Opus. **Reserve Opus for complex architectural decisions or multi-step reasoning.** ... For simple subagent tasks, specify `model: haiku`" ([Manage costs](https://code.claude.com/docs/en/costs#choose-the-right-model)). The platform pricing page says the same thing generically: "Choose Haiku for simple tasks, Sonnet for most production workloads, and Opus for the most complex reasoning."

Relevant to relying on the `opus` alias: it resolves to **Opus 5** on the Anthropic API but to **Opus 4.6** on Microsoft Foundry, and `sonnet` resolves to **Sonnet 4.5** on Bedrock and Google Cloud ([Model configuration → Model aliases](https://code.claude.com/docs/en/model-config#model-aliases)). Pin full model names if cost predictability matters.

### 5.3 Is the mixed orchestrator/worker pattern documented?

**Yes, in three forms:**

1. **`opusplan`** — a built-in alias: "In plan mode: uses `opus`... In execution mode: automatically switches to `sonnet`... This pairs Opus's reasoning for planning with Sonnet's efficiency for execution" ([Model configuration](https://code.claude.com/docs/en/model-config#opusplan-model-setting)). Cache caveat in §3.6 — each plan-mode toggle is a full cache rebuild.
2. **Per-subagent `model:` frontmatter** — `sonnet`, `opus`, `haiku`, `fable`, a full model ID, or `inherit` (default) ([Create custom subagents](https://code.claude.com/docs/en/sub-agents)). Plus `CLAUDE_CODE_SUBAGENT_MODEL` globally.
3. **The research-system pattern** — Opus lead + Sonnet subagents, the configuration that beat single-agent Opus by 90.2% ([Multi-agent research system](https://www.anthropic.com/engineering/multi-agent-research-system)); and for agent teams, "Use Sonnet for teammates" ([Manage costs](https://code.claude.com/docs/en/costs#agent-team-token-costs)).

There is also an **advisor tool** for "a hybrid approach where Claude decides mid-task when to consult a second model rather than switching at the plan boundary" — and notably its definition "sits after the cache breakpoint," so toggling `/advisor` keeps the cached prefix intact ([Model configuration](https://code.claude.com/docs/en/model-config#opusplan-model-setting); [prompt caching](https://code.claude.com/docs/en/prompt-caching#connecting-or-disconnecting-an-mcp-server)).

### 5.4 Effort level is a first-order cost lever, and it is cache-keyed

Levels on Opus 5 and Sonnet 5: `low`, `medium`, `high`, `xhigh`, `max`. **Default is `high`** on every model that supports effort (except Opus 4.7, which defaults to `xhigh`) ([Model configuration](https://code.claude.com/docs/en/model-config#adjust-effort-level)).

- `medium` "reduces token usage for cost-sensitive work that can trade off some intelligence."
- `max` "may show diminishing returns and is prone to overthinking. Test before adopting broadly."
- Effort "means more than just thinking time" — it changes files read and verification depth ([model/effort blog](https://claude.com/blog/claude-model-and-effort-level-in-claude-code)).
- Thinking tokens bill as **output tokens**, "and the default budget can be tens of thousands of tokens per request" ([Manage costs](https://code.claude.com/docs/en/costs#adjust-extended-thinking)). At Opus 5's $25/MTok output, 30k thinking tokens is $0.75 — per request. `MAX_THINKING_TOKENS` only applies to fixed-budget models; adaptive-reasoning models ignore it, so use effort levels there.
- `ultracode` (= `xhigh` + dynamic workflow orchestration per substantive task) is a session-only setting; treat it as expensive.

**Set effort once at session start.** Changing it mid-session is a full uncached re-read, same as a model switch.

---

## 6. Context-management mechanics in Claude Code (as of v2.1.239)

### 6.1 Auto-compact thresholds

Default: "Claude Code compacts when the conversation reaches the model's context limit," with exceptions ([Model configuration → Default auto-compact thresholds](https://code.claude.com/docs/en/model-config#default-auto-compact-thresholds)):
- **Sonnet 5** on the Anthropic API: native 1M window, auto-compacts at **~967K tokens** by default.
- Sonnet 4.6 / Opus 4.6 without extended context, and Opus 4.8 / Opus 5 running at 200k (Bedrock, Agent Platform, Foundry): compact at the 200K boundary.
- `CLAUDE_CODE_DISABLE_1M_CONTEXT=1` forces native-1M models to a 200K budget.

Set it yourself: `/autocompact 500k` (persists to `autoCompactWindow`), `claude --autocompact 500k` (one launch), or `CLAUDE_CODE_AUTO_COMPACT_WINDOW` (highest precedence). Accepted range **100K to 1M**, capped at the model's real window. Verified locally: `claude -h` lists `--autocompact <auto|tokens>` as "Auto-compact window size (auto, or 100k–1M tokens)".

**This is the closest thing to a "split the session" knob.** Setting `/autocompact 300k` on a Sonnet 5 run caps your per-turn cache-read tax at ~$0.06 instead of letting it drift to $0.20.

### 6.2 Extended context / 1M

Fable 5, Sonnet 5, Opus 4.6+, Sonnet 4.6 support 1M. On the Anthropic API, Fable 5, Sonnet 5, and Opus 4.7+ **always** run at 1M. On Max/Team/Enterprise, Opus is auto-upgraded to 1M; on Pro it needs usage credits. **"The 1M context window uses standard model pricing with no premium for tokens beyond 200K."** ([Model configuration → Extended context](https://code.claude.com/docs/en/model-config#extended-context))

Note the trap: a 1M window means the *default* auto-compact point is 1M, which means an unmanaged session drifts to the most expensive per-turn regime available. Extended context is a capability, not a cost saving.

### 6.3 What survives compaction

From [Explore the context window → What survives compaction](https://code.claude.com/docs/en/context-window#what-survives-compaction):

| Mechanism | After compaction |
|---|---|
| System prompt and output style | Unchanged |
| Project-root CLAUDE.md and unscoped rules | Re-injected from disk |
| Auto memory | Re-injected from disk |
| Rules with `paths:` frontmatter | **Lost** until a matching file is read again |
| Nested CLAUDE.md in subdirectories | **Lost** until a file in that subdir is read again |
| Invoked skill bodies | Re-injected, capped at **5,000 tokens per skill / 25,000 total**; oldest dropped first, truncation keeps the start of the file |

Practical consequence for long runs: **anything that must survive belongs in project-root CLAUDE.md, in a plan file on disk that gets re-read, or at the top of a SKILL.md.** Path-scoped rules will silently vanish across a compaction boundary.

Also documented: if a single file or tool output is so large that context refills immediately after each summary, "Claude Code stops auto-compacting after a few attempts and shows an error instead of looping" ([How Claude Code works](https://code.claude.com/docs/en/how-claude-code-works#when-context-fills-up)).

### 6.4 The commands, ranked by cost

| Action | Cost | Note |
|---|---|---|
| `/clear` | **Free** | "When you want a fresh start instead of continuity, `/clear` costs nothing" |
| `/rewind` | ~free | Truncates to an already-cached prefix |
| `/recap` | small | Appends a summary; prefix intact |
| `/btw` | small | Answer "never enters conversation history" |
| `/compact [focus]` | moderate warm / **large cold** | Reads the conversation it summarizes |
| Auto-compact at 1M | largest | Same mechanics, at maximum context |

Sources: [Manage costs](https://code.claude.com/docs/en/costs#why-usage-climbs-in-a-long-session), [prompt caching](https://code.claude.com/docs/en/prompt-caching#compacting-the-conversation), [Best practices](https://code.claude.com/docs/en/best-practices#manage-context-aggressively).

Partial compaction exists and is underused: `Esc Esc` → select a message checkpoint → **"Summarize from here"** (condenses forward, keeps earlier context) or **"Summarize up to here"** (condenses earlier, keeps recent in full) ([Best practices](https://code.claude.com/docs/en/best-practices#manage-context-aggressively)).

Custom compaction instructions go in CLAUDE.md under a `# Compact instructions` heading, or inline: `/compact Focus on code samples and API usage`.

### 6.5 CLAUDE.md and the mid-session edit gotcha

> "Your project-root and user-level CLAUDE.md files are read once at session start and held in memory. **Editing them mid-session does not invalidate the cache, but the edit also doesn't apply.** ... The new content loads on the next `/clear`, `/compact`, or restart."
> ([prompt caching](https://code.claude.com/docs/en/prompt-caching#editing-claude-md-mid-session))

Same for output style. Keep CLAUDE.md **under 200 lines**; move workflow-specific instructions to skills, which load on demand ([Manage costs](https://code.claude.com/docs/en/costs#move-instructions-from-claude-md-to-skills)). The best-practices test for each line: *"Would removing this cause Claude to make mistakes?"* If not, cut it — "Bloated CLAUDE.md files cause Claude to ignore your actual instructions."

### 6.6 Headless / per-task fresh context

`claude -p "prompt"` runs non-interactively with `--output-format text|json|stream-json`. "The run still creates a resumable session unless you pass `--no-session-persistence`." Documented fan-out: generate a task list, then loop `claude -p` per file with `--allowedTools` scoping; or use the built-in `/batch <instruction>`, which "split[s] the change across 5 to 30 subagents", each in its own worktree opening a PR ([Best practices → Automate and scale](https://code.claude.com/docs/en/best-practices#fan-out-across-files)).

Caveat for orchestration: **agent teams don't spawn in `-p` mode** — "a subagent that Claude names runs as an ordinary subagent even with agent teams enabled" ([agent teams](https://code.claude.com/docs/en/agent-teams#enable-agent-teams)). Also `/effort` set in `-p` mode "applies to the current session only"; pass `--effort` at launch instead.

For SDK fleets: [improve prompt caching across users and machines](https://code.claude.com/docs/en/agent-sdk/modifying-system-prompts#improve-prompt-caching-across-users-and-machines) suppresses per-machine system-prompt sections so a fleet can share one cache.

### 6.7 Other documented context reducers

- **MCP tool definitions are deferred by default** — only names and server instructions enter context until a tool is used ([Manage costs](https://code.claude.com/docs/en/costs#reduce-mcp-server-overhead)). Prefer CLI tools (`gh`, `aws`, `gcloud`) over MCP servers where possible: "they don't add any per-tool listing."
- **Hooks as preprocessors**: "Instead of Claude reading a 10,000-line log file to find errors, a hook can grep for `ERROR` and return only matching lines, reducing context from tens of thousands of tokens to hundreds" — with a working `PreToolUse` example that rewrites test commands to show only failures.
- **Code intelligence plugins** replace grep-plus-read-candidates with one "go to definition."
- `/context` for a live breakdown; `/usage` for token/cost stats (which now reset on `/clear` as of v2.1.211); `/insights` for a session-pattern HTML report. A statusline script reading `current_usage` watches `cache_read_input_tokens` vs `cache_creation_input_tokens` live: "If creation stays high turn after turn, something is changing in your prefix."
- On Pro/Max/Team/Enterprise, `/usage` flags "behaviors such as long context or cache misses... when one accounts for 10% or more of recent usage."

---

## 7. Images and screenshots in context

### 7.1 Token cost

Claude views images in 28x28-pixel patches. **An image costs `⌈width/28⌉ × ⌈height/28⌉` visual tokens** ([Vision → Resolution and token cost](https://platform.claude.com/docs/en/build-with-claude/vision#evaluate-image-size)).

Resolution tiers (Claude 4.7 and later — which includes Opus 5 and Sonnet 5 — are high-resolution):

| Tier | Models | Max long edge | Max visual tokens |
|---|---|---|---|
| High-resolution | Claude 4.7 and later | 2576 px | **4784** |
| Standard | all others | 1568 px | 1568 |

| Image | Standard tokens | High-res tokens |
|---|---|---|
| 1000x1000 | 1296 | 1296 |
| 1920x1080 | 1560 | **2691** |
| 3840x2160 (4K) | 1560 | **4784** |

Anthropic's own cost examples: at Opus 5's $5/MTok, a 1000x1000 image costs "about $6.48 per thousand" and a 4K image "about $23.92 per thousand." **"High-resolution images can use up to roughly three times more visual tokens than the same image on a standard-tier model."**

So a single 4K screenshot on Opus 5 costs ~$0.024 as fresh input — but see below.

### 7.2 Do images persist in the cached prefix?

**Yes — and that is what makes them expensive in a long session.** Images are ordinary content blocks in message history. Claude Code re-sends the full conversation every turn ([prompt caching](https://code.claude.com/docs/en/prompt-caching#how-the-cache-is-organized)), so an image pasted at turn 20 is re-read at the cache-read rate on turns 21 through 1500.

A 4K screenshot at 4,784 tokens on Opus 5 costs $0.0024 per turn as a cache read. Ten screenshots over a 1000-turn session ≈ **$24** in cache reads alone for images you looked at once. (My arithmetic from the cited token counts and rates.)

**Cache invalidation:** "Images added/removed — **invalidates message cache only**" ([Prompt caching → what invalidates the cache](https://platform.claude.com/docs/en/build-with-claude/prompt-caching)). Adding an image appends to the end, so it's cache-safe in the normal case; it is *removal* mid-history that would rebuild.

**Files API note:** for API/SDK callers, "In multi-turn conversations and agentic workflows, each request resends the full conversation history. If images are base64-encoded, the full image bytes are included in the payload on every turn... Uploading images to the Files API and referencing them by `file_id` keeps request payloads small" ([Vision](https://platform.claude.com/docs/en/build-with-claude/vision)). This reduces *payload size and latency*; the docs do not claim it reduces visual-token billing. **UNVERIFIED:** whether Claude Code uses the Files API for pasted images.

**Computer/browser use is the expensive case:** screenshots and zoom images returned in tool results are "billed as image input," and the `computer_toolset_20260801` definition alone adds ~4,500 input tokens per request, `browser_toolset_20260801` ~6,600 ([Pricing → Specific tool pricing](https://platform.claude.com/docs/en/about-claude/pricing)). A screenshot-heavy loop accumulates image tokens in the prefix on every subsequent turn.

**Request limits:** 100 images per request on 200k-context models, 600 otherwise; >20 image blocks in a request triggers a stricter per-image dimension cap (resize to ≤2000px on any edge); images from earlier turns and images nested inside `tool_result` count toward that threshold. Max dimensions 8000x8000; max 10 MB base64 on the Claude API.

Practical rule: paste a screenshot, have Claude extract what it needs in text, then `/clear` or `/compact` before the image rides along for hundreds of turns. Downsample before pasting — the high-res tier will bill 3x for fidelity a UI diff doesn't need.

---

## 8. What I could not determine

| Question | Status | What would settle it |
|---|---|---|
| A documented token threshold for splitting a session | **Not documented.** Guidance is behavioural ("clear between unrelated tasks", "after two failed corrections") | An Anthropic doc naming a number; none found across costs, best-practices, context-window, prompt-caching, model-config |
| Whether Claude Code's mid-session "clears older tool outputs" is literally the API's `clear_tool_uses_20250919` | **UNVERIFIED** | Claude Code docs describe the behaviour but not the mechanism; `claude --debug` request inspection, or an Anthropic doc linking the two |
| Whether a user can manually trigger tool-output pruning in Claude Code | **No documented command found** | Nothing surfaced in the docs I fetched; only automatic pruning is described |
| Whether Claude Code uses the Files API for pasted images (avoiding base64 re-send) | **UNVERIFIED** | Network/debug trace of a session with a pasted screenshot |
| Whether image visual-token billing differs between base64 and `file_id` sources | **Not stated either way**; the Files API tip is framed as payload/latency only | An explicit statement in Vision or Pricing |
| Exact per-turn overhead of Claude Code's system prompt on Opus 5 | Representative figure only (~4,200 tokens in the context-window simulation, which the docs call "representative numbers") | Run `/context` in a fresh session on this machine |
| The 15x multi-agent figure's applicability to coding | Figure is from a **research** system (2025-06-13); Anthropic explicitly excludes "most coding tasks" from the multi-agent sweet spot | No coding-specific multiplier published; the 7x agent-teams figure is the closest coding-adjacent number |
| Whether `/usage` subagent attribution is available on an API key | Plan-usage attribution (skills, subagents, plugins, MCP) is documented for Pro/Max/Team/Enterprise plans only | Running `/usage` on an API key here |

I did **not** run a live token/cost measurement of a 1M-context turn — that would cost real money and require a session I don't have. All dollar figures in §3 and §7.2 are arithmetic on Anthropic's published rates, and are flagged as such at each point.

---

## 9. Opinion (clearly separated from findings)

**The single change with the best ratio of effort to saving: set `/autocompact 300k` and stop running Opus as the default.** Together those two take a 1500-turn Opus-at-1M run from ~$460 to well under $80 on Sonnet 5 with a bounded window. Neither requires you to change how you work.

**My recommended shape for a long implementation run, with the cost line for each choice:**

| Choice | Cost line | Why |
|---|---|---|
| **Sonnet 5 as the session default**, `/model opus` never mid-session | $2/$10 per MTok; 2.5x cheaper than Opus 5, and a 1M Sonnet turn is cheaper than a 200k Opus turn | Docs: Sonnet "handles most coding tasks well"; implementation against a written plan is exactly the "clear specifications" case |
| **Opus 5 in a separate up-front planning session**, output written to PLAN.md | ~$5–15 for a planning session that never grows past 100k | Avoids the `opusplan` cache-rebuild-per-toggle trap entirely; the plan file, not the conversation, is the state carrier |
| **`/autocompact 300k`** | Free; caps per-turn cache read at ~$0.06 on Sonnet 5 | Documented knob, 100K–1M range, persists to user settings |
| **`/clear` at every phase boundary**, PLAN.md re-read to re-prime | Free; costs ~20–40k tokens of re-priming per restart | Docs call `/clear` free and name uncleared long sessions as the top cost driver |
| **Subagents only for: codebase search, test runs, doc fetches, adversarial review** | Each pays a cold cache start on a 5m TTL; still far cheaper than the same output landing in your main prefix forever | Explicitly the documented use case |
| **`/subtask` (fork) instead of a fresh subagent** when the side task needs your existing context | Shares the parent's prompt cache | Documented as "cheaper than a fresh subagent" |
| **Effort `high` set once at launch**, never changed mid-session | Free to set; changing it costs a full uncached re-read | Effort is part of the cache key |
| **`ENABLE_PROMPT_CACHING_1H=1`** if you're on an API key and step away often | 2x write instead of 1.25x; pays back after two reads | Avoids the ~$2–6 cold-miss cliff per break |
| **`DISABLE_AUTOUPDATER=1`** if you resume long sessions | Free | An upgrade makes resuming a long session "the most expensive request you send" |
| **Haiku 4.5 for mechanical subagents** (`model: haiku` in frontmatter) | $1/$5; 5x cheaper than Opus 5 | Explicitly recommended for "simple subagent tasks" |
| **A test-output filtering hook** | One-time setup; turns 10k-token test dumps into hundreds | Documented with a working example on the costs page |

**Where I'd push back on a common instinct:** the appeal of one-subagent-per-phase is that it *feels* like clean separation. It isn't — it's the worst of both worlds for dependent work. Each phase pays a cold cache start on a 5-minute TTL, none of them see each other's reasoning, and the coordination burden lands back on the main thread, which then has to re-read everything anyway to verify. **Fresh main sessions with a plan file on disk give you the same context hygiene at a fraction of the token cost, and the file is reviewable by a human.** Reserve real parallelism for the cases Anthropic names: independent review lenses, competing debug hypotheses, and disjoint file sets.

**On agent teams specifically:** experimental, disabled by default, ~7x tokens, cannot resume in-process teammates, and enabling them silently converts named subagents into teammates in a way that can stall an orchestration flow that waits on results. For a long implementation run with dependencies, the cost-benefit isn't close. Leave `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=0`.

**On the thing that isn't about money:** the strongest documented argument for splitting sessions is quality, not cost. Context rot is real and Anthropic says so in two separate places. If the cost argument doesn't move you, the "Claude starts forgetting earlier instructions" argument should.

---

## Appendix: what I ran and what I removed

**Executed on this machine:**
- `claude --version` → `2.1.239 (Claude Code)`
- `claude -h | head -40` → confirmed `--autocompact <auto|tokens>` accepts "auto, or 100k–1M tokens"; `--bg/--background`, `--agents`, `--append-system-prompt`, `--bare` present in this build
- Two inline `python -c` calculations for the cost tables in §3.2–§3.4. No files written by them.

**Created:** only this file, at `docs/research/long-running-claude-code-session-economics.md`. Nothing scaffolded, nothing to clean up. No files outside `docs/research/` were modified. No git operations were performed.

**Sources fetched (all primary):**
- https://platform.claude.com/docs/en/about-claude/pricing
- https://platform.claude.com/docs/en/build-with-claude/prompt-caching
- https://platform.claude.com/docs/en/build-with-claude/context-editing
- https://platform.claude.com/docs/en/build-with-claude/vision
- https://code.claude.com/docs/en/costs
- https://code.claude.com/docs/en/prompt-caching
- https://code.claude.com/docs/en/sub-agents
- https://code.claude.com/docs/en/agent-teams
- https://code.claude.com/docs/en/best-practices
- https://code.claude.com/docs/en/model-config
- https://code.claude.com/docs/en/context-window
- https://code.claude.com/docs/en/how-claude-code-works
- https://www.anthropic.com/engineering/multi-agent-research-system (2025-06-13)
- https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents (2025-09-29)
- https://claude.com/blog/lessons-from-building-claude-code-prompt-caching-is-everything (2026-04-30)
- https://claude.com/blog/claude-model-and-effort-level-in-claude-code (2026-07-07)

**Doc-URL drift worth noting:** `docs.claude.com/en/docs/...` now 302-redirects to `platform.claude.com/docs/en/...`, and Claude Code docs live at `code.claude.com/docs/en/...` with no `/docs/claude-code/` path segment. Older `docs.anthropic.com/en/docs/claude-code/*` links 404 on direct fetch. A machine-readable index is at https://code.claude.com/docs/llms.txt.
