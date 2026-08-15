---
name: design
description: Answer an under-determined visual question with three variants in one self-contained HTML artifact, at desktop and mobile, then record the decision so implementation reuses the real design system. Use before writing UI code whenever more than one defensible visual answer exists.
---

More than one defensible visual answer exists, so the cheapest place to be wrong is a mockup.
Nothing here is production code and nothing here gets copied into the app.

## Preflight: find the design system first

**Brownfield.** Find the app shell — whatever the application loads at document head **is** the
design system, by definition — and inline its stylesheets in the shell's own load order. Embed
local assets. Where an external font cannot be fetched, declare it and **never invent a
substitute**; the fallback is device-dependent and naming one produces a lie about what the user
will see.

Success is: shell found, and **zero unresolved local references**. An unresolved local reference
means the extractor misread the project — stop and fix that rather than shipping an approximate
artifact.

The failure mode here is not CSS, it is markup. Extracted CSS comes out exact; hand-rolled markup
renders components invisible (white on transparent is the classic). **Grep for the real component
markup and copy it** rather than reconstructing it from the class names.

**Greenfield, or no extractable CSS-file system.** Say so and why, in one line, then invent — and
know that whatever is approved becomes the seed of the project's design system.

## The artifact

One self-contained HTML page, published at a **stable URL** so it can be refreshed rather than
chased across rounds, and republished to that same URL every round.

- **Three variants** by default, never fewer than two, and meaningfully different — not three
  spacings of one idea.
- **Every variant at both breakpoints.** Desktop and mobile, side by side, in the same artifact.
  Mobile is not a follow-up round; it has been asked for unprompted too many times.
- **A recommendation with its cost line.** One option, the reason, and what choosing it costs.
- Theme-aware, responsive, and self-contained: no external scripts, fonts, images or styles.

Iterate inside the artifact. Mixing is normal and expected — "the action bar from B with the
docked panel from C" is a legitimate answer, so keep the variants decomposable.

## The decision record outranks the mockup

When a direction is approved, write `docs/design/<effort>.md` **before any implementation**:

- Hierarchy and what earns emphasis.
- Spacing rhythm and the scale it comes from.
- Components **reused** from the existing system — by name, with their real file paths.
- Components genuinely **new**, and why nothing existing covered it.
- Choices **rejected**, with reasons, so they are not quietly reintroduced later.

The artifact shows the approved direction; the record is what binds. State this explicitly in the
handoff: the HTML is reference material for proportion and behaviour, **not markup to copy**.
