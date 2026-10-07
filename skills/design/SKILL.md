---
name: design
description: Answer an under-determined visual question with three variants in one self-contained HTML artifact, at desktop and mobile, then record the decision so implementation reuses the real design system. Use before writing UI code whenever more than one defensible visual answer exists.
model: sonnet
effort: high
---

More than one defensible visual answer exists, so the cheapest place to be wrong is a mockup.
Nothing here is production code and nothing here gets copied into the app.

## No design-system extraction

**Do not extract, inline or read the app's stylesheets.** The mockup answers layout, hierarchy
and behaviour — not exact tokens — and a faithful copy of the design system cost tens of
thousands of tokens per pass for a fidelity nobody was judging. Style the variants with a small
neutral palette of your own, declared once as CSS custom properties, and keep them visibly
plain so nobody mistakes them for production styling.

Fidelity to the real system is the **decision record's** job, not the mockup's: it names the
reused components by real file path, and implementation builds from those.

## The artifact

One self-contained HTML page, published at a **stable URL** so it can be refreshed rather than
chased across rounds, and republished to that same URL every round.

- **Three variants** by default, never fewer than two, and meaningfully different — not three
  spacings of one idea.
- **Every variant at both breakpoints.** Desktop and mobile, side by side, in the same artifact.
  Mobile is not a follow-up round.
- **A recommendation with its cost line.** One option, the reason, and what choosing it costs.
- Theme-aware, responsive, self-contained: no external scripts, fonts, images or styles.

Iterate inside the artifact. Mixing is normal — "the action bar from B with the docked panel from
C" is a legitimate answer, so keep the variants decomposable.

## When `explore` invoked this

A brainstorm runs this pass on the direction it is about to recommend, before it publishes. Two
things change, and only these two:

- **The artifact is theirs.** Publish the variants as a section of the explore artifact at the
  URL you were handed, below the options and the recommendation — not a new page. The stable-URL
  rule is unchanged; that URL is simply the stable one. Everything else about the artifact still
  applies: three variants, both breakpoints, a recommendation with its cost line.
- **The record waits.** Nothing has been approved yet and there is no effort slug, so do not
  write `docs/design/<effort>.md`. Say in one line that the record is pending approval. If the
  user approves a direction there and then, write it — under the effort slug if `plan` has
  produced one, and under the explore topic if it has not.

## The decision record outranks the mockup

When a direction is approved, write `docs/design/<effort>.md` **before any implementation**:
hierarchy and what earns emphasis; spacing rhythm and its scale; components **reused** from the
existing system, by name with real file paths — find them with one Agent call,
`subagent_type: Explore`, `model: haiku`, asking for **paths and one-line purposes only, never
file contents**; components genuinely **new**, and why nothing
existing covered it; choices **rejected**, with reasons, so they are not quietly reintroduced.

State this explicitly in the handoff: the HTML is reference material for proportion and
behaviour, **not markup to copy**.

Why there is no extraction, and why three variants: `reference.md`.
