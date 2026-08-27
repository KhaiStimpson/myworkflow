#!/usr/bin/env python3
"""D6 - re-derive what sessions actually cost, from the transcripts on disk.

The figures in docs/spec-session-economics.md came from this. It exists so that
re-deriving them is minutes rather than a research pass, and so the claim the
spec makes - that a chain of phase-sized sessions is cheaper than one long
thread - gets settled by measurement after the change lands instead of by
modelling before it.

This is a developer tool. Nothing runs it automatically and it costs nothing
when nobody does.

  python scripts/measure-sessions.py                    # sessions over 400 KB
  python scripts/measure-sessions.py --project sqlviewer
  python scripts/measure-sessions.py --iterations 4c15e762
"""

import argparse
import glob
import json
import os
import sys

# Published per-million-token rates: input, cache write, cache read, output.
# Cache write is 1.25x input and cache read is 0.10x input on every model, so a
# row that does not hold that ratio is a typo. Checked against the published
# rates 2026-08-27.
RATES = {
    "opus":   (5.00, 6.25, 0.50, 25.00),   # Opus 5, and Opus 4.8/4.7/4.6
    "sonnet": (2.00, 2.50, 0.20, 10.00),   # Sonnet 5
    "sonnet46": (3.00, 3.75, 0.30, 15.00), # Sonnet 4.6 - the older, dearer tier
    "haiku":  (1.00, 1.25, 0.10, 5.00),    # Haiku 4.5
}


# The ratio check as an assertion, not just a comment. This file has already
# carried one wrong row (Sonnet 4.6 rates used for Sonnet 5, which understated
# the Opus/Sonnet gap as 1.67x when it is a flat 2.5x); it should not do so
# again silently.
for _name, (_in, _cw, _cr, _out) in RATES.items():
    assert abs(_cw - _in * 1.25) < 1e-9, f"{_name}: cache write is not 1.25x input"
    assert abs(_cr - _in * 0.10) < 1e-9, f"{_name}: cache read is not 0.10x input"


def family(model):
    """Map a model id onto a rate row.

    Order matters: the sonnet-4-6 test has to precede the generic sonnet one.
    Anything unrecognised falls through to opus, which over-states rather than
    under-states - a cost report that flatters the bill is the worse failure.
    """
    m = model or ""
    if "haiku" in m:
        return "haiku"
    if "sonnet-4-6" in m or "sonnet-4.6" in m:
        return "sonnet46"
    if "sonnet" in m:
        return "sonnet"
    return "opus"


def cost(usage, fam):
    inp, cw, cr, out = RATES[fam]
    return (
        usage.get("input_tokens", 0) * inp
        + usage.get("cache_creation_input_tokens", 0) * cw
        + usage.get("cache_read_input_tokens", 0) * cr
        + usage.get("output_tokens", 0) * out
    ) / 1e6


def context_of(usage):
    """What the model was handed on this turn - the number that drives the bill."""
    return (
        usage.get("input_tokens", 0)
        + usage.get("cache_read_input_tokens", 0)
        + usage.get("cache_creation_input_tokens", 0)
    )


def assistant_turns(path):
    """Yield (usage, model, is_sidechain, content) per assistant turn."""
    with open(path, encoding="utf-8", errors="replace") as fh:
        for line in fh:
            line = line.strip()
            if not line:
                continue
            try:
                rec = json.loads(line)
            except ValueError:
                continue
            if rec.get("type") != "assistant":
                continue
            msg = rec.get("message", {})
            usage = msg.get("usage")
            if not usage:
                continue
            yield usage, msg.get("model", "?"), bool(rec.get("isSidechain")), msg.get("content") or []


def scan(path):
    turns = peak = subagents = 0
    actual = as_opus = as_sonnet = read_spend = 0.0
    reads = writes = output = 0
    models = {}
    for usage, model, sidechain, _ in assistant_turns(path):
        turns += 1
        if sidechain:
            subagents += 1
        fam = family(model)
        models[model] = models.get(model, 0) + 1
        peak = max(peak, context_of(usage))
        cache_read = usage.get("cache_read_input_tokens", 0)
        reads += cache_read
        writes += usage.get("cache_creation_input_tokens", 0)
        output += usage.get("output_tokens", 0)
        # Priced per turn at that turn's own model - a session that switched
        # mid-run must not be costed at one blended rate. Getting this wrong is
        # exactly what put $220 of phantom spend in the original findings.
        read_spend += cache_read * RATES[fam][2] / 1e6
        actual += cost(usage, fam)
        as_opus += cost(usage, "opus")
        as_sonnet += cost(usage, "sonnet")
    return dict(
        path=path, turns=turns, peak=peak, subagents=subagents, models=models,
        actual=actual, as_opus=as_opus, as_sonnet=as_sonnet, read_spend=read_spend,
        reads=reads, writes=writes, output=output,
    )


def iterations(path):
    """Segment a session by loop iteration.

    A /loop iteration ends with the ScheduleWakeup that queues the next one, so
    those calls are the boundaries. This is how the per-iteration cost table in
    the spec was produced, and it is the view that shows the actual finding:
    the same work costs several times more late in a thread than early in it.
    """
    segments, current = [], []
    for usage, model, _, content in assistant_turns(path):
        current.append((context_of(usage), cost(usage, family(model))))
        if any(
            isinstance(b, dict) and b.get("type") == "tool_use" and b.get("name") == "ScheduleWakeup"
            for b in content
        ):
            segments.append(current)
            current = []
    if current:
        segments.append(current)
    return segments


def find(pattern, project=None):
    root = os.path.expanduser("~/.claude/projects")
    hits = glob.glob(os.path.join(root, "*", "*.jsonl"))
    if project:
        hits = [h for h in hits if project.lower() in os.path.basename(os.path.dirname(h)).lower()]
    if pattern:
        hits = [h for h in hits if os.path.basename(h).startswith(pattern)]
    return hits


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--min-kb", type=int, default=400, help="ignore transcripts smaller than this (default 400)")
    ap.add_argument("--top", type=int, default=10, help="how many sessions to list (default 10)")
    ap.add_argument("--project", help="substring match on the project directory")
    ap.add_argument("--iterations", metavar="SESSION_PREFIX", help="per-iteration breakdown for one session")
    args = ap.parse_args()

    if args.iterations:
        matches = find(args.iterations, args.project)
        if not matches:
            print("no transcript matching %r" % args.iterations, file=sys.stderr)
            return 1
        path = matches[0]
        print("%s\n" % path)
        print("%4s %7s %12s %10s %10s" % ("iter", "turns", "ctx at end", "cost", "cumulative"))
        total = 0.0
        for n, seg in enumerate(iterations(path), 1):
            spend = sum(c for _, c in seg)
            total += spend
            print("%4d %7d %12s %10s %10s"
                  % (n, len(seg), "{:,}".format(seg[-1][0]), "$%.2f" % spend, "$%.2f" % total))
        print("\ntotal ${:,.0f}".format(total))
        return 0

    rows = [scan(p) for p in find(None, args.project)
            if os.path.getsize(p) >= args.min_kb * 1024]
    rows.sort(key=lambda r: r["turns"], reverse=True)
    if not rows:
        print("no transcripts over %d KB" % args.min_kb, file=sys.stderr)
        return 1

    print("%-10s %6s %5s %10s %14s %10s %9s  %s"
          % ("session", "turns", "subs", "peak ctx", "cache reads", "output", "actual", "project"))
    for r in rows[:args.top]:
        print("%-10s %6d %5d %10s %14s %10s %9s  %s" % (
            os.path.basename(r["path"])[:8], r["turns"], r["subagents"],
            "{:,}".format(r["peak"]), "{:,}".format(r["reads"]), "{:,}".format(r["output"]),
            "${:,.0f}".format(r["actual"]),
            os.path.basename(os.path.dirname(r["path"])),
        ))

    shown = rows[:args.top]
    actual = sum(r["actual"] for r in shown)
    as_opus = sum(r["as_opus"] for r in shown)
    as_sonnet = sum(r["as_sonnet"] for r in shown)
    reads = sum(r["reads"] for r in shown)
    read_spend = sum(r["read_spend"] for r in shown)

    print("\nacross %d sessions" % len(shown))
    print("  actual                ${:,.0f}".format(actual))
    print("  if all Opus           ${:,.0f}".format(as_opus))
    print("  if all Sonnet         ${:,.0f}".format(as_sonnet))
    if as_sonnet:
        print("  model-switch lever    {:.2f}x  (not the headline; splitting is)".format(actual / as_sonnet))
    if actual:
        print("  cache reads           {:,} tokens, ~{:.0f}% of spend".format(reads, 100 * read_spend / actual))

    models = {}
    for r in shown:
        for m, n in r["models"].items():
            models[m] = models.get(m, 0) + n
    print("  models                " + ", ".join("%s x%d" % (m, n) for m, n in sorted(models.items())))
    return 0


if __name__ == "__main__":
    sys.exit(main())
